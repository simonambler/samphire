import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      'vue': 'vue/dist/vue.esm-bundler.js'
    }
  },
  server: {
    host: '127.0.0.1',
    proxy: {
      // string shorthand: http://localhost:5173/samphire/data -> http://localhost:8080/samphire/data
      '/samphire/data': 'http://localhost:8080',
      '/samphire/login': 'http://localhost:8080',
      '/samphire/logout': 'http://localhost:8080',
      '/samphire/home': 'http://localhost:8080',
      '/static/samphire': 'http://localhost:8080',
    }
  },
  build: {
    // generate .vite/manifest.json in outDir
    manifest: true,
    rollupOptions: {
      // overwrite default .html entry
      input: 'src/main.js',
    },
  },
  base: '/samphire/',
})
