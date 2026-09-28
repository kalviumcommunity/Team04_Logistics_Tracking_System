const nodemailer = require('nodemailer');

// Initialize Transporter
let transporter = null;

function getTransporter() {
  if (transporter) return transporter;

  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const secure = process.env.SMTP_SECURE === 'true' || port === 465;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (user && pass) {
    if (process.env.EMAIL_SERVICE) {
      transporter = nodemailer.createTransport({
        service: process.env.EMAIL_SERVICE,
        auth: { user, pass }
      });
    } else {
      transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass }
      });
    }
  }

  return transporter;
}

/**
 * Generates a cryptographically secure 6-digit numeric OTP
 */
function generateOtp() {
  const crypto = require('crypto');
  return crypto.randomInt(100000, 1000000).toString();
}

/**
 * Sends an OTP email to the user
 * @param {string} toEmail - Recipient email address
 * @param {string} otp - 6-digit verification code
 * @param {string} [userName] - Optional recipient name
 */
async function sendOtpEmail(toEmail, otp, userName = 'DeliverSync User') {
  const sender = process.env.EMAIL_FROM || '"DeliverSync Logistics" <no-reply@deliversync.com>';
  const transport = getTransporter();

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>DeliverSync Verification Code</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 0; }
        .container { max-width: 540px; margin: 30px auto; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
        .header { background: linear-gradient(135deg, #1E1B4B 0%, #312E81 50%, #4F46E5 100%); padding: 32px 24px; text-align: center; }
        .header h1 { color: #FFFFFF; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
        .header p { color: #C7D2FE; margin: 6px 0 0 0; font-size: 13px; }
        .content { padding: 32px 28px; text-align: center; }
        .greeting { font-size: 16px; font-weight: 700; color: #1E293B; margin-bottom: 12px; text-align: left; }
        .instruction { font-size: 14px; color: #64748B; line-height: 1.6; margin-bottom: 24px; text-align: left; }
        .otp-card { background: #EEF2FF; border: 2px dashed #6366F1; border-radius: 14px; padding: 20px; margin: 24px 0; }
        .otp-label { font-size: 11px; font-weight: 800; color: #4F46E5; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 8px; }
        .otp-code { font-size: 36px; font-weight: 900; color: #1E1B4B; letter-spacing: 8px; font-family: 'Courier New', Courier, monospace; }
        .expiry-badge { display: inline-block; background: #FEF3C7; color: #92400E; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 700; margin-top: 14px; }
        .security-notice { font-size: 12px; color: #94A3B8; line-height: 1.5; margin-top: 24px; border-top: 1px solid #F1F5F9; padding-top: 16px; text-align: left; }
        .footer { background: #F8FAFC; padding: 18px 24px; text-align: center; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>DeliverSync</h1>
          <p>Real-Time Logistics & Fleet Synchronization</p>
        </div>
        <div class="content">
          <div class="greeting">Hello, ${userName} 👋</div>
          <div class="instruction">
            Thank you for registering with DeliverSync. To verify your email address and activate your account, please enter the following 6-digit verification code:
          </div>
          
          <div class="otp-card">
            <div class="otp-label">Your Verification Code</div>
            <div class="otp-code">${otp}</div>
            <div class="expiry-badge">⏱ Expires in 10 minutes</div>
          </div>

          <div class="security-notice">
            🔒 <strong>Security Tip:</strong> Never share this verification code with anyone. DeliverSync administrators or support staff will never ask for your code. If you did not request this verification, please safely ignore this email.
          </div>
        </div>
        <div class="footer">
          &copy; ${new Date().getFullYear()} DeliverSync Technologies Inc. All rights reserved.
        </div>
      </div>
    </body>
    </html>
  `;

  if (!transport) {
    console.warn('\n=============================================================');
    console.warn(`[DeliverSync Mailer] SMTP credentials not fully configured in .env.`);
    console.warn(`[OTP GENERATED] To: ${toEmail} | Code: ${otp}`);
    console.warn(`[CONFIG REQUIRED] Set SMTP_USER and SMTP_PASS in backend/.env to send real emails.`);
    console.warn('=============================================================\n');
    return { success: true, simulated: true, otp };
  }

  try {
    const info = await transport.sendMail({
      from: sender,
      to: toEmail,
      subject: `${otp} is your DeliverSync verification code`,
      text: `Your DeliverSync email verification code is: ${otp}. This code will expire in 10 minutes. Do not share it with anyone.`,
      html: htmlContent
    });

    console.log(`[DeliverSync Mailer] Verification email sent to ${toEmail} (MessageId: ${info.messageId})`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error(`[DeliverSync Mailer] Error sending email to ${toEmail}:`, err.message);
    throw new Error(`Failed to send email: ${err.message}`);
  }
}

module.exports = {
  generateOtp,
  sendOtpEmail,
  getTransporter
};
