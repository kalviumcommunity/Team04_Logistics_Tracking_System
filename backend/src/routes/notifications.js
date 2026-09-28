const express = require('express');
const router = express.Router();
const prisma = require('../utils/prisma');
const { authenticate } = require('../middlewares/auth');

// GET /api/notifications
router.get('/', authenticate, async (req, res) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });

    const unreadCount = notifications.filter(n => !n.isRead).length;

    return res.json({ notifications, unreadCount });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch notifications.' });
  }
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const notification = await prisma.notification.updateMany({
      where: { id, userId: req.user.id },
      data: { isRead: true }
    });

    return res.json({ message: 'Notification marked as read.' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update notification.' });
  }
});

// PATCH /api/notifications/read-all
router.patch('/read-all', authenticate, async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true }
    });

    return res.json({ message: 'All notifications marked as read.' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update notifications.' });
  }
});

module.exports = router;
