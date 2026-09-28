const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate, authorize } = require('../middlewares/auth');

// GET /api/escalations
router.get('/', authenticate, async (req, res) => {
  try {
    const { status } = req.query;
    let whereClause = {};
    if (status && status !== 'ALL') {
      whereClause.status = status;
    }

    // Delivery Executive sees only own escalations
    if (req.user.role === 'DELIVERY_EXECUTIVE') {
      whereClause.failureReport = {
        executiveId: req.user.id
      };
    }

    const escalations = await prisma.escalation.findMany({
      where: whereClause,
      include: {
        delivery: { include: { customer: true } },
        failureReport: {
          include: {
            executive: { select: { id: true, fullName: true, phone: true } }
          }
        },
        resolvedBy: { select: { id: true, fullName: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    return res.json({ escalations });
  } catch (error) {
    return res.status(500).json({ message: 'Error fetching escalations.' });
  }
});

// PATCH /api/escalations/:id (OPERATIONS role only)
router.patch('/:id', authenticate, authorize(['OPERATIONS']), async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolutionNotes, priority } = req.body;

    const escalation = await prisma.escalation.findUnique({
      where: { id },
      include: {
        delivery: true,
        failureReport: { include: { executive: true } }
      }
    });

    if (!escalation) {
      return res.status(404).json({ message: 'Escalation not found.' });
    }

    const isResolving = status === 'RESOLVED';
    const updatedEscalation = await prisma.escalation.update({
      where: { id },
      data: {
        status: status || escalation.status,
        priority: priority || escalation.priority,
        resolutionNotes: resolutionNotes || escalation.resolutionNotes,
        resolvedById: isResolving ? req.user.id : escalation.resolvedById,
        resolvedAt: isResolving ? new Date() : escalation.resolvedAt
      },
      include: {
        delivery: { include: { customer: true } },
        failureReport: { include: { executive: true } },
        resolvedBy: { select: { id: true, fullName: true } }
      }
    });

    // Notify assigned Executive and Dispatcher
    const recipients = [escalation.failureReport.executiveId, escalation.delivery.createdById].filter(Boolean);
    for (const uid of [...new Set(recipients)]) {
      await prisma.notification.create({
        data: {
          userId: uid,
          title: `Escalation ${status || 'Updated'}`,
          message: `Escalation for delivery ${escalation.delivery.trackingNumber} resolved by Operations.`,
          type: 'ESCALATION_RESOLVED',
          link: `/escalations/${id}`
        }
      });
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('escalation:resolved', updatedEscalation);
      io.emit('notification:new', {});
    }

    return res.json({ message: 'Escalation updated successfully.', escalation: updatedEscalation });
  } catch (error) {
    console.error('Update escalation error:', error);
    return res.status(500).json({ message: 'Error updating escalation.' });
  }
});

module.exports = router;
