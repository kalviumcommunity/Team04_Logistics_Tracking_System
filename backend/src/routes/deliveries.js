const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate, authorize } = require('../middlewares/auth');
const { validateStateTransition } = require('../utils/stateMachine');

function generateTrackingNumber() {
  const num = Math.floor(100000 + Math.random() * 900000);
  return `DS-${num}`;
}

// GET /api/deliveries (Scoped by role)
router.get('/', authenticate, async (req, res) => {
  try {
    const { status } = req.query;
    let whereClause = {};

    if (status && status !== 'ALL') {
      whereClause.status = status;
    }

    // Role-based visibility: Executive views assigned deliveries only
    if (req.user.role === 'DELIVERY_EXECUTIVE') {
      whereClause.assignments = {
        some: {
          executiveId: req.user.id
        }
      };
    }

    const deliveries = await prisma.delivery.findMany({
      where: whereClause,
      include: {
        customer: true,
        createdBy: { select: { id: true, fullName: true, email: true } },
        assignments: {
          orderBy: { assignedAt: 'desc' },
          take: 1,
          include: {
            executive: { select: { id: true, fullName: true, email: true, phone: true } }
          }
        },
        failureReports: {
          take: 1,
          orderBy: { timestamp: 'desc' },
          include: { escalation: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = deliveries.map(d => ({
      ...d,
      assignedExecutive: d.assignments.length > 0 ? d.assignments[0].executive : null,
      latestFailure: d.failureReports.length > 0 ? d.failureReports[0] : null
    }));

    return res.json({ deliveries: formatted });
  } catch (error) {
    console.error('Fetch deliveries error:', error);
    return res.status(500).json({ message: 'Failed to fetch deliveries.' });
  }
});

// GET /api/deliveries/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const delivery = await prisma.delivery.findFirst({
      where: { OR: [{ id }, { trackingNumber: id }] },
      include: {
        customer: true,
        createdBy: { select: { id: true, fullName: true, email: true } },
        assignments: {
          include: { executive: { select: { id: true, fullName: true, email: true, phone: true } } },
          orderBy: { assignedAt: 'desc' }
        },
        statusHistory: {
          include: { updatedBy: { select: { id: true, fullName: true, role: true } } },
          orderBy: { createdAt: 'asc' }
        },
        failureReports: {
          include: { escalation: true },
          orderBy: { timestamp: 'desc' }
        }
      }
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    // Role check: Executive can only view if assigned
    if (req.user.role === 'DELIVERY_EXECUTIVE') {
      const isAssigned = delivery.assignments.some(a => a.executiveId === req.user.id);
      if (!isAssigned) {
        return res.status(403).json({ message: 'Access denied. You are not assigned to this delivery.' });
      }
    }

    const assignedExecutive = delivery.assignments.length > 0 ? delivery.assignments[0].executive : null;

    return res.json({
      delivery: {
        ...delivery,
        assignedExecutive
      }
    });
  } catch (error) {
    return res.status(500).json({ message: 'Error retrieving delivery details.' });
  }
});

// POST /api/deliveries (DISPATCHER only)
router.post('/', authenticate, authorize(['DISPATCHER']), async (req, res) => {
  try {
    const { customerName, customerPhone, customerEmail, pickupAddress, deliveryAddress, city, deliveryDate, deliveryTime, assignedExecutiveId, remarks } = req.body;

    if (!customerName || !customerPhone || !pickupAddress || !deliveryAddress || !city || !deliveryDate || !deliveryTime) {
      return res.status(400).json({ message: 'Please provide all required delivery fields.' });
    }

    // 1. Find or create Customer record
    let customer = await prisma.customer.findFirst({ where: { phone: customerPhone } });
    if (!customer) {
      customer = await prisma.customer.create({
        data: {
          fullName: customerName,
          phone: customerPhone,
          email: customerEmail || null,
          address: deliveryAddress,
          city
        }
      });
    }

    const trackingNumber = generateTrackingNumber();
    const initialStatus = assignedExecutiveId ? 'ASSIGNED' : 'PENDING';

    // 2. Create Delivery linked via customerId
    const delivery = await prisma.delivery.create({
      data: {
        trackingNumber,
        pickupAddress,
        deliveryAddress,
        city,
        deliveryDate,
        deliveryTime,
        remarks: remarks || '',
        status: initialStatus,
        eta: '45 mins',
        customerId: customer.id,
        createdById: req.user.id
      },
      include: { customer: true }
    });

    // 3. Add initial status history
    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: delivery.id,
        status: initialStatus,
        updatedById: req.user.id,
        remarks: `Delivery created by Dispatcher ${req.user.fullName}`
      }
    });

    // 4. Assign Executive if selected
    if (assignedExecutiveId) {
      await prisma.deliveryAssignment.create({
        data: {
          deliveryId: delivery.id,
          executiveId: assignedExecutiveId,
          assignedById: req.user.id
        }
      });

      await prisma.notification.create({
        data: {
          userId: assignedExecutiveId,
          title: 'New Delivery Assigned',
          message: `Delivery ${delivery.trackingNumber} to ${customer.fullName} assigned to you.`,
          type: 'ASSIGNMENT',
          link: `/deliveries/${delivery.id}`
        }
      });

      const io = req.app.get('io');
      if (io) {
        io.emit('delivery:assigned', { deliveryId: delivery.id, executiveId: assignedExecutiveId });
        io.emit('notification:new', { userId: assignedExecutiveId });
      }
    }

    return res.status(201).json({ message: 'Delivery created successfully.', delivery });
  } catch (error) {
    console.error('Create delivery error:', error);
    return res.status(500).json({ message: 'Failed to create delivery.' });
  }
});

// POST /api/deliveries/:id/assign (DISPATCHER only)
router.post('/:id/assign', authenticate, authorize(['DISPATCHER']), async (req, res) => {
  try {
    const { id } = req.params;
    const { executiveId } = req.body;

    if (!executiveId) {
      return res.status(400).json({ message: 'Executive ID is required.' });
    }

    const delivery = await prisma.delivery.findUnique({ where: { id }, include: { customer: true } });
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    // Validate state machine: PENDING -> ASSIGNED
    if (!validateStateTransition(delivery.status, 'ASSIGNED')) {
      return res.status(400).json({
        message: `Cannot assign delivery in status '${delivery.status}'. Valid transition required.`
      });
    }

    await prisma.deliveryAssignment.create({
      data: {
        deliveryId: id,
        executiveId,
        assignedById: req.user.id
      }
    });

    const updatedDelivery = await prisma.delivery.update({
      where: { id },
      data: { status: 'ASSIGNED' },
      include: { customer: true }
    });

    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: id,
        status: 'ASSIGNED',
        updatedById: req.user.id,
        remarks: 'Assigned to delivery executive'
      }
    });

    await prisma.notification.create({
      data: {
        userId: executiveId,
        title: 'Delivery Assigned',
        message: `Delivery ${delivery.trackingNumber} has been assigned to you.`,
        type: 'ASSIGNMENT',
        link: `/deliveries/${id}`
      }
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('delivery:assigned', { deliveryId: id, executiveId });
      io.emit('notification:new', { userId: executiveId });
    }

    return res.json({ message: 'Delivery assigned successfully.', delivery: updatedDelivery });
  } catch (error) {
    return res.status(500).json({ message: 'Error assigning delivery.' });
  }
});

// PATCH /api/deliveries/:id/reassign (DISPATCHER only)
router.patch('/:id/reassign', authenticate, authorize(['DISPATCHER']), async (req, res) => {
  try {
    const { id } = req.params;
    const { executiveId } = req.body;

    if (!executiveId) {
      return res.status(400).json({ message: 'New executive ID is required.' });
    }

    const delivery = await prisma.delivery.findUnique({ where: { id }, include: { customer: true } });
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    await prisma.deliveryAssignment.create({
      data: {
        deliveryId: id,
        executiveId,
        assignedById: req.user.id
      }
    });

    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: id,
        status: delivery.status,
        updatedById: req.user.id,
        remarks: 'Reassigned to new delivery executive'
      }
    });

    await prisma.notification.create({
      data: {
        userId: executiveId,
        title: 'Delivery Reassigned to You',
        message: `Delivery ${delivery.trackingNumber} was reassigned to you.`,
        type: 'ASSIGNMENT',
        link: `/deliveries/${id}`
      }
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('delivery:assigned', { deliveryId: id, executiveId });
      io.emit('notification:new', { userId: executiveId });
    }

    return res.json({ message: 'Delivery reassigned successfully.' });
  } catch (error) {
    return res.status(500).json({ message: 'Error reassigning delivery.' });
  }
});

// PATCH /api/deliveries/:id/status (Backend Enforced State Machine)
router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, remarks, location } = req.body;

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

    // Role check: Delivery Executive can update status for assigned delivery
    if (req.user.role === 'DELIVERY_EXECUTIVE') {
      const isAssigned = delivery.assignments.some(a => a.executiveId === req.user.id);
      if (!isAssigned) {
        return res.status(403).json({ message: 'Forbidden. You can only update status for your assigned deliveries.' });
      }
    }

    // Enforce Backend State Machine Validation
    if (!validateStateTransition(delivery.status, status)) {
      return res.status(400).json({
        message: `Invalid status transition from '${delivery.status}' to '${status}'. Expected flow: PENDING -> ASSIGNED -> IN_TRANSIT -> DELIVERED / FAILED.`
      });
    }

    const updatedDelivery = await prisma.delivery.update({
      where: { id },
      data: { status },
      include: { customer: true }
    });

    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: id,
        status,
        updatedById: req.user.id,
        remarks: remarks || `Status updated to ${status}`,
        location: location || 'GPS Field App Coordinates'
      }
    });

    const io = req.app.get('io');
    if (io) {
      if (status === 'IN_TRANSIT') {
        io.emit('delivery:in_transit', { deliveryId: id, trackingNumber: delivery.trackingNumber });
      } else if (status === 'DELIVERED') {
        io.emit('delivery:delivered', { deliveryId: id, trackingNumber: delivery.trackingNumber });
      }
      io.emit('notification:new', {});
    }

    return res.json({ message: `Delivery status updated to ${status}`, delivery: updatedDelivery });
  } catch (error) {
    console.error('Update status error:', error);
    return res.status(500).json({ message: 'Error updating status.' });
  }
});

// PUT /api/deliveries/:id (DISPATCHER only - edit delivery info)
router.put('/:id', authenticate, authorize(['DISPATCHER']), async (req, res) => {
  try {
    const { id } = req.params;
    const { customerName, customerPhone, customerEmail, pickupAddress, deliveryAddress, city, deliveryDate, deliveryTime, remarks, eta } = req.body;

    const delivery = await prisma.delivery.findUnique({ where: { id }, include: { customer: true } });
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    if (delivery.status === 'DELIVERED' || delivery.status === 'CANCELLED') {
      return res.status(400).json({ message: `Cannot edit delivery with status '${delivery.status}'.` });
    }

    // Update customer info if provided
    if (delivery.customerId && (customerName || customerPhone || customerEmail || deliveryAddress || city)) {
      await prisma.customer.update({
        where: { id: delivery.customerId },
        data: {
          fullName: customerName || undefined,
          phone: customerPhone || undefined,
          email: customerEmail !== undefined ? customerEmail : undefined,
          address: deliveryAddress || undefined,
          city: city || undefined,
        }
      });
    }

    const updated = await prisma.delivery.update({
      where: { id },
      data: {
        pickupAddress: pickupAddress || undefined,
        deliveryAddress: deliveryAddress || undefined,
        city: city || undefined,
        deliveryDate: deliveryDate || undefined,
        deliveryTime: deliveryTime || undefined,
        remarks: remarks !== undefined ? remarks : undefined,
        eta: eta !== undefined ? eta : undefined,
      },
      include: {
        customer: true,
        assignments: {
          orderBy: { assignedAt: 'desc' },
          take: 1,
          include: { executive: { select: { id: true, fullName: true, email: true, phone: true } } }
        }
      }
    });

    const formatted = {
      ...updated,
      assignedExecutive: updated.assignments.length > 0 ? updated.assignments[0].executive : null
    };

    return res.json({ message: 'Delivery updated successfully.', delivery: formatted });
  } catch (error) {
    console.error('Update delivery error:', error);
    return res.status(500).json({ message: 'Failed to update delivery.' });
  }
});

// DELETE /api/deliveries/:id (DISPATCHER only cancellation)
router.delete('/:id', authenticate, authorize(['DISPATCHER']), async (req, res) => {
  try {
    const { id } = req.params;
    const delivery = await prisma.delivery.findUnique({ where: { id } });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found.' });
    }

    if (!validateStateTransition(delivery.status, 'CANCELLED')) {
      return res.status(400).json({
        message: `Cannot cancel delivery in status '${delivery.status}'. Deliveries in transit or completed cannot be cancelled.`
      });
    }

    await prisma.delivery.update({
      where: { id },
      data: { status: 'CANCELLED' }
    });

    await prisma.deliveryStatusHistory.create({
      data: {
        deliveryId: id,
        status: 'CANCELLED',
        updatedById: req.user.id,
        remarks: 'Cancelled by Dispatcher'
      }
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('notification:new', {});
    }

    return res.json({ message: 'Delivery order cancelled successfully.' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to cancel delivery.' });
  }
});

module.exports = router;
