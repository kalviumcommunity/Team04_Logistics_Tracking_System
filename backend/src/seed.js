const prisma = require('./utils/prisma');
const bcrypt = require('bcryptjs');

async function seed() {
  console.log('🌱 Seeding DeliverSync Database...');

  // Clean old data in proper order
  await prisma.notification.deleteMany();
  await prisma.escalation.deleteMany();
  await prisma.failureReport.deleteMany();
  await prisma.deliveryStatusHistory.deleteMany();
  await prisma.deliveryAssignment.deleteMany();
  await prisma.delivery.deleteMany();
  await prisma.customer.deleteMany();
  await prisma.user.deleteMany();

  const hashedPassword = await bcrypt.hash('password123', 10);

  // 1. Create Users
  const dispatcher = await prisma.user.create({
    data: {
      fullName: 'David Miller',
      email: 'dispatcher@deliversync.com',
      phone: '+1 (555) 234-5678',
      password: hashedPassword,
      role: 'DISPATCHER',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=DavidMiller',
      isVerified: true
    }
  });

  const exec1 = await prisma.user.create({
    data: {
      fullName: 'Alex Rivera',
      email: 'executive@deliversync.com',
      phone: '+1 (555) 876-5432',
      password: hashedPassword,
      role: 'DELIVERY_EXECUTIVE',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=AlexRivera',
      isVerified: true
    }
  });

  const exec2 = await prisma.user.create({
    data: {
      fullName: 'Marcus Vance',
      email: 'executive2@deliversync.com',
      phone: '+1 (555) 987-6543',
      password: hashedPassword,
      role: 'DELIVERY_EXECUTIVE',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=MarcusVance',
      isVerified: true
    }
  });

  const ops = await prisma.user.create({
    data: {
      fullName: 'Sarah Jenkins',
      email: 'ops@deliversync.com',
      phone: '+1 (555) 345-6789',
      password: hashedPassword,
      role: 'OPERATIONS',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=SarahJenkins',
      isVerified: true
    }
  });

  console.log('✅ Users created: Dispatcher, 2 Executives, Operations');

  // 2. Create Customers
  const customer1 = await prisma.customer.create({
    data: {
      fullName: 'Elena Rostova',
      phone: '+1 (555) 111-2222',
      email: 'elena@example.com',
      address: '742 Evergreen Terrace, Apt 4B',
      city: 'Metropolis'
    }
  });

  const customer2 = await prisma.customer.create({
    data: {
      fullName: 'Robert Langdon',
      phone: '+1 (555) 333-4444',
      email: 'robert@example.com',
      address: '42 Wallaby Way, Suite 12',
      city: 'Metropolis'
    }
  });

  const customer3 = await prisma.customer.create({
    data: {
      fullName: 'Samantha Wright',
      phone: '+1 (555) 666-7777',
      email: 'samantha@example.com',
      address: '888 Beacon Hill Ave, Gate 2',
      city: 'Metropolis'
    }
  });

  const customer4 = await prisma.customer.create({
    data: {
      fullName: 'TechCorp Solutions',
      phone: '+1 (555) 999-0000',
      email: 'orders@techcorp.com',
      address: '500 Innovation Parkway, Floor 3',
      city: 'Metropolis'
    }
  });

  const customer5 = await prisma.customer.create({
    data: {
      fullName: 'Kevin Park',
      phone: '+1 (555) 123-4567',
      email: 'kevin@example.com',
      address: '33 Riverside Drive',
      city: 'Metropolis'
    }
  });

  console.log('✅ Customers created');

  // 3. Create Deliveries (linked to Customer model)
  const d1 = await prisma.delivery.create({
    data: {
      trackingNumber: 'DS-94021',
      pickupAddress: 'Warehouse A, Tech Hub Blvd',
      deliveryAddress: customer1.address,
      city: customer1.city,
      deliveryDate: '2026-08-19',
      deliveryTime: '14:30',
      remarks: 'Handle with care - fragile electronic components',
      status: 'IN_TRANSIT',
      eta: '25 mins',
      customerId: customer1.id,
      createdById: dispatcher.id
    }
  });

  await prisma.deliveryAssignment.create({
    data: { deliveryId: d1.id, executiveId: exec1.id, assignedById: dispatcher.id }
  });
  await prisma.deliveryStatusHistory.createMany({
    data: [
      { deliveryId: d1.id, status: 'PENDING', updatedById: dispatcher.id, remarks: 'Delivery created in system' },
      { deliveryId: d1.id, status: 'ASSIGNED', updatedById: dispatcher.id, remarks: 'Assigned to Alex Rivera' },
      { deliveryId: d1.id, status: 'IN_TRANSIT', updatedById: exec1.id, remarks: 'Picked up from Hub A, en route to customer' }
    ]
  });

  const d2 = await prisma.delivery.create({
    data: {
      trackingNumber: 'DS-88194',
      pickupAddress: 'Hub B, 100 Logistics Way',
      deliveryAddress: customer2.address,
      city: customer2.city,
      deliveryDate: '2026-08-19',
      deliveryTime: '11:00',
      remarks: 'Call customer 5 mins before arrival',
      status: 'DELIVERED',
      eta: 'Completed',
      customerId: customer2.id,
      createdById: dispatcher.id
    }
  });

  await prisma.deliveryAssignment.create({
    data: { deliveryId: d2.id, executiveId: exec2.id, assignedById: dispatcher.id }
  });
  await prisma.deliveryStatusHistory.createMany({
    data: [
      { deliveryId: d2.id, status: 'PENDING', updatedById: dispatcher.id, remarks: 'Order created' },
      { deliveryId: d2.id, status: 'ASSIGNED', updatedById: dispatcher.id, remarks: 'Assigned to Marcus Vance' },
      { deliveryId: d2.id, status: 'IN_TRANSIT', updatedById: exec2.id, remarks: 'Out for delivery' },
      { deliveryId: d2.id, status: 'DELIVERED', updatedById: exec2.id, remarks: 'Signed by recipient Robert Langdon' }
    ]
  });

  // Failed delivery with Escalation
  const d3 = await prisma.delivery.create({
    data: {
      trackingNumber: 'DS-77402',
      pickupAddress: 'Express Depot 3',
      deliveryAddress: customer3.address,
      city: customer3.city,
      deliveryDate: '2026-08-19',
      deliveryTime: '09:45',
      remarks: 'Gated community code required',
      status: 'FAILED',
      eta: 'Failed',
      customerId: customer3.id,
      createdById: dispatcher.id
    }
  });

  await prisma.deliveryAssignment.create({
    data: { deliveryId: d3.id, executiveId: exec1.id, assignedById: dispatcher.id }
  });
  await prisma.deliveryStatusHistory.createMany({
    data: [
      { deliveryId: d3.id, status: 'PENDING', updatedById: dispatcher.id, remarks: 'Created' },
      { deliveryId: d3.id, status: 'ASSIGNED', updatedById: dispatcher.id, remarks: 'Assigned to Alex Rivera' },
      { deliveryId: d3.id, status: 'IN_TRANSIT', updatedById: exec1.id, remarks: 'En route to Beacon Hill' },
      { deliveryId: d3.id, status: 'FAILED', updatedById: exec1.id, remarks: 'Customer unavailable & gate locked' }
    ]
  });

  const failureReport = await prisma.failureReport.create({
    data: {
      deliveryId: d3.id,
      executiveId: exec1.id,
      reason: 'CUSTOMER_UNAVAILABLE',
      remarks: 'Attempted call 3 times. Gate locked and guard refused entry without pre-clearance.',
      evidenceUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400&q=80'
    }
  });

  await prisma.escalation.create({
    data: {
      failureReportId: failureReport.id,
      deliveryId: d3.id,
      status: 'OPEN',
      priority: 'HIGH'
    }
  });

  // Pending delivery unassigned
  const d4 = await prisma.delivery.create({
    data: {
      trackingNumber: 'DS-66291',
      pickupAddress: 'Central Hub 1',
      deliveryAddress: customer4.address,
      city: customer4.city,
      deliveryDate: '2026-08-19',
      deliveryTime: '16:00',
      remarks: 'Deliver to reception desk',
      status: 'PENDING',
      eta: 'Unassigned',
      customerId: customer4.id,
      createdById: dispatcher.id
    }
  });
  await prisma.deliveryStatusHistory.create({
    data: { deliveryId: d4.id, status: 'PENDING', updatedById: dispatcher.id, remarks: 'Created and awaiting assignment' }
  });

  // Assigned delivery
  const d5 = await prisma.delivery.create({
    data: {
      trackingNumber: 'DS-55119',
      pickupAddress: 'Hub C, South District',
      deliveryAddress: customer5.address,
      city: customer5.city,
      deliveryDate: '2026-08-19',
      deliveryTime: '13:00',
      remarks: 'Signature required',
      status: 'ASSIGNED',
      eta: '45 mins',
      customerId: customer5.id,
      createdById: dispatcher.id
    }
  });
  await prisma.deliveryAssignment.create({
    data: { deliveryId: d5.id, executiveId: exec2.id, assignedById: dispatcher.id }
  });
  await prisma.deliveryStatusHistory.createMany({
    data: [
      { deliveryId: d5.id, status: 'PENDING', updatedById: dispatcher.id, remarks: 'Created' },
      { deliveryId: d5.id, status: 'ASSIGNED', updatedById: dispatcher.id, remarks: 'Assigned to Marcus Vance' }
    ]
  });

  // 4. Create Notifications
  await prisma.notification.createMany({
    data: [
      {
        userId: exec1.id,
        title: 'New Delivery Assigned',
        message: 'Delivery DS-94021 has been assigned to you. Customer: Elena Rostova.',
        type: 'ASSIGNMENT',
        link: `/deliveries/${d1.id}`,
        isRead: false
      },
      {
        userId: ops.id,
        title: '🚨 New Escalation Created',
        message: 'Delivery DS-77402 failed (CUSTOMER_UNAVAILABLE). Action required.',
        type: 'ESCALATION',
        link: `/escalations`,
        isRead: false
      },
      {
        userId: dispatcher.id,
        title: 'Delivery Completed ✅',
        message: 'Delivery DS-88194 delivered successfully by Marcus Vance.',
        type: 'STATUS_CHANGE',
        link: `/deliveries/${d2.id}`,
        isRead: true
      },
      {
        userId: exec2.id,
        title: 'New Delivery Assigned',
        message: 'Delivery DS-55119 has been assigned to you. Customer: Kevin Park.',
        type: 'ASSIGNMENT',
        link: `/deliveries/${d5.id}`,
        isRead: false
      }
    ]
  });

  console.log('✅ Notifications created');
  console.log('');
  console.log('==================================================');
  console.log('🎉 DeliverSync Database Seeded Successfully!');
  console.log('==================================================');
  console.log('');
  console.log('📋 DEVELOPMENT LOGIN CREDENTIALS:');
  console.log('--------------------------------------------------');
  console.log('DISPATCHER:          dispatcher@deliversync.com');
  console.log('DELIVERY EXECUTIVE:  executive@deliversync.com');
  console.log('DELIVERY EXECUTIVE2: executive2@deliversync.com');
  console.log('OPERATIONS:          ops@deliversync.com');
  console.log('ALL PASSWORDS:       password123');
  console.log('--------------------------------------------------');
  console.log('');
  console.log('⚠️  These credentials are for DEVELOPMENT ONLY.');
  console.log('    Change passwords before deploying to production!');
  console.log('==================================================');
}

seed()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
