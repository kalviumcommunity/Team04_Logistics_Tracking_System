const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const customerRoutes = require('./routes/customers');
const deliveryRoutes = require('./routes/deliveries');
const failureRoutes = require('./routes/failures');
const escalationRoutes = require('./routes/escalations');
const notificationRoutes = require('./routes/notifications');
const analyticsRoutes = require('./routes/analytics');
const executiveRoutes = require('./routes/executives');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE']
  }
});

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.options('*', cors());
app.use(express.json());

app.set('io', io);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/deliveries', deliveryRoutes);
app.use('/api', failureRoutes);
app.use('/api/escalations', escalationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/executives', executiveRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'DeliverSync PostgreSQL Backend Service is active.' });
});

io.on('connection', (socket) => {
  console.log('⚡ Socket client connected:', socket.id);

  socket.on('join:room', (room) => {
    socket.join(room);
  });

  socket.on('disconnect', () => {
    console.log('⚡ Socket client disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 DeliverSync Backend running on http://localhost:${PORT} (0.0.0.0:${PORT})`);
});
