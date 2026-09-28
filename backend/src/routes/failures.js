const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate, authorize } = require('../middlewares/auth');
const { validateStateTransition } = require('../utils/stateMachine');

// POST /api/deliveries/:id/failure (DELIVERY_EXECUTIVE only)
router.post('/deliveries/:id/failure', authenticate, authorize(['DELIVERY_EXECUTIVE']), async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, remarks, evidenceUrl } = req.body;

    if (!reason || !remarks) {
      return res.status(400).json({ message: 'Failure reason and remarks are required.' });
    }

    const delivery = await prisma.delivery.findUnique({
      where: { id },
      include: {
        customer: true,
        assignments: { orderBy: { assignedAt: 'desc' }, take: 1 }
      }
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    // Verify Executive is assigned
    const isAssigned = delivery.assignments.some(a => a.executiveId === req.user.id);
    if (!isAssigned) {
      return res.status(403).json({ message: 'Forbidden. You can only report failure for assigned deliveries.' });
    }

    // Validate State Machine: IN_TRANSIT -> FAILED
    if (!validateStateTransition(delivery.status, 'FAILED')) {
      return res.status(400).json({
        message: `Cannot mark delivery as FAILED from status '${delivery.status}'. Must be IN_TRANSIT.`
      });
    }

    // 1. Update delivery status to FAILED
    await prisma.delivery.update({
      where: { id },
      data: { status: 'FAILED' }
    });

    // 2. Add Status History
    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: id,
        status: 'FAILED',
        updatedById: req.user.id,
        remarks: `Delivery failed: ${reason} - ${remarks}`
      }
    });

    // 3. Create Failure Report
    const failureReport = await prisma.failureReport.create({
      data: {
        deliveryId: id,
        executiveId: req.user.id,
        reason,
        remarks,
        evidenceUrl: evidenceUrl || 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400&q=80'
      }
    });

    // 4. Create Escalation for Operations Team
    const escalation = await prisma.escalation.create({
      data: {
        failureReportId: failureReport.id,
        deliveryId: id,
        status: 'OPEN',
        priority: reason === 'CUSTOMER_REJECTED' || reason === 'VEHICLE_ISSUE' ? 'CRITICAL' : 'HIGH'
      }
    });

    // 5. Notify Operations Users
    const opsUsers = await prisma.user.findMany({ where: { role: 'OPERATIONS' } });
    for (const opsUser of opsUsers) {
      await prisma.notification.create({
        data: {
          userId: opsUser.id,
          title: '🚨 New Escalation Created',
          message: `Delivery ${delivery.trackingNumber} failed (${reason}). Action required.`,
          type: 'ESCALATION',
          link: `/escalations/${escalation.id}`
        }
      });
    }

    // 6. Socket.IO Events
    const io = req.app.get('io');
    if (io) {
      io.emit('delivery:failed', { deliveryId: id, trackingNumber: delivery.trackingNumber });
      io.emit('escalation:created', escalation);
      io.emit('notification:new', {});
    }

    return res.status(201).json({
      message: 'Failure report submitted and escalation logged for Operations.',
      failureReport,
      escalation
    });
  } catch (error) {
    console.error('Failure report error:', error);
    return res.status(500).json({ message: 'Failed to submit failure report.' });
  }
});

// GET /api/failures (Operations & Dispatcher viewable)
router.get('/failures', authenticate, authorize(['OPERATIONS', 'DISPATCHER']), async (req, res) => {
  try {
    const failures = await prisma.failureReport.findMany({
      include: {
        delivery: { include: { customer: true } },
        executive: { select: { id: true, fullName: true, phone: true } },
        escalation: true
      },
      orderBy: { timestamp: 'desc' }
    });

    return res.json({ failures });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch failure reports.' });
  }
});

module.exports = router;
