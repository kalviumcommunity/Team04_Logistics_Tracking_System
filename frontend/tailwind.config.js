/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          blue: '#1769E8',
          blueDark: '#2454D6',
          cyan: '#12C7C5',
          purple: '#7B2FF7',
          navy: '#14213D',
          bg: '#F7F9FC',
          success: '#16B364',
          warning: '#F59E0B',
          error: '#EF4444',
        }
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'sans-serif'],
      },
      boxShadow: {
        'mobile-soft': '0 8px 30px rgba(20, 33, 61, 0.08)',
        'card-glow': '0 4px 20px rgba(23, 105, 232, 0.12)',
        'frame': '0 25px 60px -15px rgba(20, 33, 61, 0.35)',
      }
    },
  },
  plugins: [],
}
