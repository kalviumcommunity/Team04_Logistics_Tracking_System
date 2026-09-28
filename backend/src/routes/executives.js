const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate } = require('../middlewares/auth');

// GET /api/executives
router.get('/', authenticate, async (req, res) => {
  try {
    const executives = await prisma.user.findMany({
      where: { role: 'DELIVERY_EXECUTIVE' },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        avatarUrl: true,
        assignedDeliveries: {
          include: { delivery: true },
          orderBy: { assignedAt: 'desc' }
        }
      }
    });

    const formatted = executives.map(exec => {
      const activeCount = exec.assignedDeliveries.filter(a => ['ASSIGNED', 'IN_TRANSIT'].includes(a.delivery.status)).length;
      return {
        id: exec.id,
        fullName: exec.fullName,
        email: exec.email,
        phone: exec.phone,
        avatarUrl: exec.avatarUrl,
        activeDeliveriesCount: activeCount,
        status: activeCount > 0 ? 'ON_DUTY' : 'AVAILABLE'
      };
    });

    return res.json({ executives: formatted });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch delivery executives.' });
  }
});

module.exports = router;
