/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,ts,tsx,js,jsx}'],
  theme: {
    extend: {
      colors: {
        base: '#1a1a2e',
        card: '#20203a',
        accent: '#4361ee',
        muted: '#a5b4fc'
      }
    }
  },
  plugins: []
}
