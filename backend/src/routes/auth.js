const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../utils/prisma');
const { authenticate, JWT_SECRET } = require('../middlewares/auth');
const { generateOtp, sendOtpEmail } = require('../utils/mailer');

// ── Validation Helpers ────────────────────────────────────────────────────────

/**
 * RFC 5322 Compliant Email Format Validator
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const trimmed = email.trim();
  if (trimmed.length < 5 || trimmed.length > 254) return false;
  
  // Disallow spaces, consecutive dots, leading/trailing dots in domain
  if (trimmed.includes(' ') || trimmed.includes('..')) return false;

  const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;
  if (!emailRegex.test(trimmed)) return false;

  const [local, domain] = trimmed.split('@');
  if (!local || !domain || local.length > 64) return false;
  
  // TLD must have at least 2 alpha characters
  const parts = domain.split('.');
  if (parts.length < 2) return false;
  const tld = parts[parts.length - 1];
  if (!/^[a-zA-Z]{2,24}$/.test(tld)) return false;

  return true;
}

/**
 * Password Strength Validator (>=8 chars, 1 uppercase, 1 lowercase, 1 number)
 */
function isValidPassword(password) {
  if (!password || typeof password !== 'string') return false;
  if (password.length < 8) return false;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasDigit = /[0-9]/.test(password);
  return hasUpper && hasLower && hasDigit;
}

/**
 * Phone Number Validator (min 7 digits, max 15 digits, valid format, no dummy numbers)
 */
function isValidPhone(phone) {
  if (!phone || typeof phone !== 'string') return false;
  const trimmed = phone.trim();
  const phoneRegex = /^\+?[0-9\s\-()]{7,20}$/;
  if (!phoneRegex.test(trimmed)) return false;

  const digits = trimmed.replace(/\D/g, '');
  if (digits.length < 7 || digits.length > 15) return false;

  // Reject dummy sequences
  if (/^(\d)\1+$/.test(digits)) return false; // 000000, 111111, etc.
  if ('0123456789'.includes(digits) || '9876543210'.includes(digits)) return false;

  return true;
}

/**
 * Full Name Validator (trimmed, min 2 chars, letters and common name punctuation)
 */
function isValidName(name) {
  if (!name || typeof name !== 'string') return false;
  const trimmed = name.trim();
  if (trimmed.length < 2 || trimmed.length > 70) return false;
  
  // Must contain alphabetic characters, not numbers only
  if (!/[a-zA-Z]/.test(trimmed)) return false;
  if (/\d/.test(trimmed)) return false;

  return /^[a-zA-Z\s.'-]{2,70}$/.test(trimmed);
}

// ── 1. POST /api/auth/register ────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const { fullName, email, phone, password, confirmPassword, role } = req.body;

    // 1. Name validation
    if (!fullName || !isValidName(fullName)) {
      return res.status(400).json({
        message: 'Please enter a valid full name.'
      });
    }

    // 2. Email format validation
    if (!email || !isValidEmail(email)) {
      return res.status(400).json({
        message: 'Please enter a valid email address.'
      });
    }
    const cleanEmail = email.trim().toLowerCase();

    // 3. Phone validation
    if (!phone || !isValidPhone(phone)) {
      return res.status(400).json({
        message: 'Please enter a valid phone number.'
      });
    }

    // 4. Password validation
    if (!password || !isValidPassword(password)) {
      return res.status(400).json({
        message: 'Password must be at least 8 characters and include at least one uppercase letter, one lowercase letter, and one number.'
      });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({
        message: 'Passwords do not match.'
      });
    }

    // 5. Role validation
    let normalizedRole = (role || 'DISPATCHER').toUpperCase();
    if (normalizedRole === 'FIELD_EXECUTIVE') normalizedRole = 'DELIVERY_EXECUTIVE';
    if (normalizedRole === 'OPERATIONS_MANAGER') normalizedRole = 'OPERATIONS';

    const validRoles = ['DISPATCHER', 'DELIVERY_EXECUTIVE', 'OPERATIONS'];
    if (!validRoles.includes(normalizedRole)) {
      return res.status(400).json({
        message: 'Invalid user role specified.'
      });
    }

    // 6. Check existing user
    const existingUser = await prisma.user.findUnique({
      where: { email: cleanEmail }
    });

    if (existingUser && existingUser.isVerified) {
      return res.status(400).json({
        message: 'An account with this email already exists. Please log in.'
      });
    }

    // Generate secure 6-digit OTP & hash
    const otp = generateOtp();
    const otpHash = await bcrypt.hash(otp, 10);
    const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    const hashedPassword = await bcrypt.hash(password, 10);
    const avatarUrl = `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(fullName.trim())}`;

    let user;
    if (existingUser && !existingUser.isVerified) {
      // Update existing unverified user with new registration info and new OTP
      user = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          fullName: fullName.trim(),
          phone: phone.trim(),
          password: hashedPassword,
          role: normalizedRole,
          avatarUrl,
          otpHash,
          otpExpiresAt,
          otpAttempts: 0,
          lastOtpSentAt: new Date()
        }
      });
    } else {
      // Create new user record (unverified)
      user = await prisma.user.create({
        data: {
          fullName: fullName.trim(),
          email: cleanEmail,
          phone: phone.trim(),
          password: hashedPassword,
          role: normalizedRole,
          avatarUrl,
          isVerified: false,
          otpHash,
          otpExpiresAt,
          otpAttempts: 0,
          lastOtpSentAt: new Date()
        }
      });
    }

    // Send OTP email
    try {
      await sendOtpEmail(cleanEmail, otp, user.fullName);
    } catch (emailErr) {
      console.error('Email send failed during registration:', emailErr.message);
      // We still return requiresVerification so the user can resend once config is checked
    }

    return res.status(201).json({
      message: 'Verification code sent to your email.',
      requiresVerification: true,
      email: cleanEmail,
      role: user.role
    });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({
      message: 'An unexpected error occurred during registration. Please try again.'
    });
  }
});

// ── 2. POST /api/auth/verify-otp ──────────────────────────────────────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !isValidEmail(email)) {
      return res.status(400).json({
        message: 'Please enter a valid email address.'
      });
    }
    const cleanEmail = email.trim().toLowerCase();

    if (!otp || typeof otp !== 'string' || !/^\d{6}$/.test(otp.trim())) {
      return res.status(400).json({
        message: 'Please enter a valid 6-digit verification code.'
      });
    }
    const cleanOtp = otp.trim();

    const user = await prisma.user.findUnique({
      where: { email: cleanEmail }
    });

    if (!user) {
      return res.status(404).json({
        message: 'User account not found.'
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        message: 'This account is already verified. Please log in.'
      });
    }

    if (!user.otpHash || !user.otpExpiresAt) {
      return res.status(400).json({
        message: 'No active verification code found. Please request a new code.'
      });
    }

    // Check expiration (10 minutes)
    if (new Date() > new Date(user.otpExpiresAt)) {
      return res.status(400).json({
        message: 'This verification code has expired. Please request a new one.'
      });
    }

    // Check attempt limits (max 5)
    if (user.otpAttempts >= 5) {
      // Invalidate OTP on excessive attempts
      await prisma.user.update({
        where: { id: user.id },
        data: { otpHash: null, otpExpiresAt: null }
      });
      return res.status(400).json({
        message: 'Too many incorrect attempts. Please request a new verification code.'
      });
    }

    // Verify OTP hash
    const isMatch = await bcrypt.compare(cleanOtp, user.otpHash);
    if (!isMatch) {
      await prisma.user.update({
        where: { id: user.id },
        data: { otpAttempts: { increment: 1 } }
      });
      return res.status(400).json({
        message: 'The verification code is incorrect.'
      });
    }

    // Mark as verified & clear OTP
    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        isVerified: true,
        otpHash: null,
        otpExpiresAt: null,
        otpAttempts: 0
      }
    });

    // Generate JWT token
    const token = jwt.sign(
      {
        id: updatedUser.id,
        email: updatedUser.email,
        fullName: updatedUser.fullName,
        role: updatedUser.role
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Create welcome notification
    await prisma.notification.create({
      data: {
        userId: updatedUser.id,
        title: 'Email Verified Successfully 🎉',
        message: `Welcome to DeliverSync! Your ${updatedUser.role.toLowerCase().replace('_', ' ')} account is now fully active.`,
        type: 'SYSTEM'
      }
    }).catch(() => {});

    return res.json({
      message: 'Email verified successfully.',
      token,
      user: {
        id: updatedUser.id,
        fullName: updatedUser.fullName,
        email: updatedUser.email,
        phone: updatedUser.phone,
        role: updatedUser.role,
        avatarUrl: updatedUser.avatarUrl
      }
    });
  } catch (error) {
    console.error('OTP verification error:', error);
    return res.status(500).json({
      message: 'An unexpected error occurred while verifying code. Please try again.'
    });
  }
});

// ── 3. POST /api/auth/resend-otp ──────────────────────────────────────────────
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !isValidEmail(email)) {
      return res.status(400).json({
        message: 'Please enter a valid email address.'
      });
    }
    const cleanEmail = email.trim().toLowerCase();

    const user = await prisma.user.findUnique({
      where: { email: cleanEmail }
    });

    if (!user) {
      return res.status(404).json({
        message: 'No account found with this email address.'
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        message: 'This account is already verified. Please log in.'
      });
    }

    // Resend cooldown: 60 seconds
    if (user.lastOtpSentAt) {
      const secondsSinceLastOtp = Math.floor((Date.now() - new Date(user.lastOtpSentAt).getTime()) / 1000);
      if (secondsSinceLastOtp < 60) {
        const remaining = 60 - secondsSinceLastOtp;
        return res.status(429).json({
          message: `Please wait ${remaining} seconds before requesting a new code.`,
          retryAfter: remaining
        });
      }
    }

    // Generate new OTP & invalidate previous
    const otp = generateOtp();
    const otpHash = await bcrypt.hash(otp, 10);
    const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        otpHash,
        otpExpiresAt,
        otpAttempts: 0,
        lastOtpSentAt: new Date()
      }
    });

    // Send new OTP email
    try {
      await sendOtpEmail(cleanEmail, otp, user.fullName);
    } catch (emailErr) {
      console.error('Email send failed during resend-otp:', emailErr.message);
      return res.status(500).json({
        message: "We couldn't send the verification code. Please try again."
      });
    }

    return res.json({
      message: 'A new verification code has been sent to your email.'
    });
  } catch (error) {
    console.error('Resend OTP error:', error);
    return res.status(500).json({
      message: 'An unexpected error occurred while resending code. Please try again.'
    });
  }
});

// ── 4. POST /api/auth/login ───────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !isValidEmail(email)) {
      return res.status(400).json({
        message: 'Please enter a valid email address.'
      });
    }
    const cleanEmail = email.trim().toLowerCase();

    if (!password) {
      return res.status(400).json({
        message: 'Password is required.'
      });
    }

    const user = await prisma.user.findUnique({
      where: { email: cleanEmail }
    });

    if (!user) {
      return res.status(401).json({
        message: 'Invalid email or password.'
      });
    }

    const isValidPass = await bcrypt.compare(password, user.password);
    if (!isValidPass) {
      return res.status(401).json({
        message: 'Invalid email or password.'
      });
    }

    // Enforce email verification
    if (!user.isVerified) {
      // Auto-send fresh OTP if cooldown permits
      const canSend = !user.lastOtpSentAt || (Date.now() - new Date(user.lastOtpSentAt).getTime()) > 60000;
      if (canSend) {
        const otp = generateOtp();
        const otpHash = await bcrypt.hash(otp, 10);
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
        await prisma.user.update({
          where: { id: user.id },
          data: {
            otpHash,
            otpExpiresAt,
            otpAttempts: 0,
            lastOtpSentAt: new Date()
          }
        });
        sendOtpEmail(cleanEmail, otp, user.fullName).catch(() => {});
      }

      return res.status(403).json({
        message: 'Please verify your email address to continue.',
        requiresVerification: true,
        email: user.email,
        role: user.role
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.json({
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        avatarUrl: user.avatarUrl
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({
      message: 'An unexpected error occurred during login. Please try again.'
    });
  }
});

// ── 5. GET /api/auth/me ───────────────────────────────────────────────────────
router.get('/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isVerified: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.json({ user });
  } catch (error) {
    return res.status(500).json({ message: 'Error fetching profile.' });
  }
});

// ── 6. POST /api/auth/logout ──────────────────────────────────────────────────
router.post('/logout', (req, res) => {
  return res.json({ message: 'Logged out successfully.' });
});

module.exports = router;
