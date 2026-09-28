const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate } = require('../middlewares/auth');

// GET /api/analytics/overview
router.get('/overview', authenticate, async (req, res) => {
  try {
    const totalDeliveries = await prisma.delivery.count();
    const pendingCount = await prisma.delivery.count({ where: { status: 'PENDING' } });
    const assignedCount = await prisma.delivery.count({ where: { status: 'ASSIGNED' } });
    const inTransitCount = await prisma.delivery.count({ where: { status: 'IN_TRANSIT' } });
    const deliveredCount = await prisma.delivery.count({ where: { status: 'DELIVERED' } });
    const failedCount = await prisma.delivery.count({ where: { status: 'FAILED' } });
    const cancelledCount = await prisma.delivery.count({ where: { status: 'CANCELLED' } });

    const activeDeliveries = assignedCount + inTransitCount;

    const totalEscalations = await prisma.escalation.count();
    const openEscalations = await prisma.escalation.count({ where: { status: 'OPEN' } });
    const inProgressEscalations = await prisma.escalation.count({ where: { status: 'IN_PROGRESS' } });
    const resolvedEscalations = await prisma.escalation.count({ where: { status: 'RESOLVED' } });

    const completedOrFailed = deliveredCount + failedCount;
    const successRate = completedOrFailed > 0 ? ((deliveredCount / completedOrFailed) * 100).toFixed(1) : '100.0';
    const failureRate = completedOrFailed > 0 ? ((failedCount / completedOrFailed) * 100).toFixed(1) : '0.0';

    // Status breakdown array for charts
    const statusDistribution = [
      { name: 'Pending', value: pendingCount, color: '#F59E0B' },
      { name: 'Assigned', value: assignedCount, color: '#1769E8' },
      { name: 'In Transit', value: inTransitCount, color: '#12C7C5' },
      { name: 'Delivered', value: deliveredCount, color: '#16B364' },
      { name: 'Failed', value: failedCount, color: '#EF4444' },
      { name: 'Cancelled', value: cancelledCount, color: '#64748B' }
    ];

    // Failure trends by reason
    const failureReports = await prisma.failureReport.findMany();
    const reasonCounts = {};
    failureReports.forEach(fr => {
      reasonCounts[fr.reason] = (reasonCounts[fr.reason] || 0) + 1;
    });

    const failureTrends = Object.keys(reasonCounts).map(reason => ({
      reason: reason.replace('_', ' '),
      count: reasonCounts[reason]
    }));

    // Executive performance overview
    const executives = await prisma.user.findMany({
      where: { role: 'DELIVERY_EXECUTIVE' },
      include: {
        assignedDeliveries: {
          include: { delivery: true }
        }
      }
    });

    const executivePerformance = executives.map(exec => {
      const deliveries = exec.assignedDeliveries.map(a => a.delivery);
      const total = deliveries.length;
      const completed = deliveries.filter(d => d.status === 'DELIVERED').length;
      const failed = deliveries.filter(d => d.status === 'FAILED').length;
      const active = deliveries.filter(d => ['ASSIGNED', 'IN_TRANSIT'].includes(d.status)).length;
      const rate = (completed + failed) > 0 ? Math.round((completed / (completed + failed)) * 100) : 100;

      return {
        id: exec.id,
        name: exec.fullName,
        avatar: exec.avatarUrl,
        total,
        completed,
        failed,
        active,
        successRate: rate
      };
    });

    return res.json({
      metrics: {
        totalDeliveries,
        activeDeliveries,
        assignedCount,
        inTransitCount,
        deliveredCount,
        failedCount,
        openEscalations,
        inProgressEscalations,
        resolvedEscalations,
        totalEscalations,
        successRate: `${successRate}%`,
        failureRate: `${failureRate}%`
      },
      statusDistribution,
      failureTrends,
      executivePerformance
    });
  } catch (error) {
    console.error('Analytics error:', error);
    return res.status(500).json({ message: 'Failed to compute analytics.' });
  }
});

module.exports = router;
