import { html } from '@/lib/juris'

export default function MainLayout({ title = 'Rails8 Juris', children }) {
  return html`
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow-sm border-b border-gray-200">
        <div class="container mx-auto px-4">
          <div class="flex items-center justify-between h-16">
            <div class="flex items-center space-x-8">
              <a href="/" class="text-xl font-bold text-gray-900">
                Rails8 Juris
              </a>
              <div class="hidden md:flex space-x-4">
                <a href="/" class="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium">
                  Home
                </a>
                <a href="/products" class="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium">
                  Products
                </a>
                <a href="/product_exports" class="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium">
                  Exports
                </a>
                <a href="/admin" class="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium">
                  Admin
                </a>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <!-- Main Content -->
      <main class="py-6">
        ${children}
      </main>

      <!-- Footer -->
      <footer class="bg-white border-t border-gray-200 mt-auto">
        <div class="container mx-auto px-4 py-6">
          <p class="text-center text-gray-500 text-sm">
            © ${new Date().getFullYear()} Rails8 Juris. Built with Rails 8 and Juris.js.
          </p>
        </div>
      </footer>
    </div>
  `
}
