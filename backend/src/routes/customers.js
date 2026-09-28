const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate, authorize } = require('../middlewares/auth');

// GET /api/customers
router.get('/', authenticate, async (req, res) => {
  try {
    const customers = await prisma.customer.findMany({
      include: {
        _count: { select: { deliveries: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    return res.json({ customers });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch customers.' });
  }
});

// POST /api/customers (DISPATCHER & OPERATIONS)
router.post('/', authenticate, authorize(['DISPATCHER', 'OPERATIONS']), async (req, res) => {
  try {
    const { fullName, email, phone, address, city } = req.body;

    if (!fullName || !phone || !address || !city) {
      return res.status(400).json({ message: 'Full name, phone, address, and city are required.' });
    }

    const customer = await prisma.customer.create({
      data: {
        fullName,
        email: email || null,
        phone,
        address,
        city
      }
    });

    return res.status(201).json({ message: 'Customer created successfully.', customer });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to create customer.' });
  }
});

module.exports = router;
