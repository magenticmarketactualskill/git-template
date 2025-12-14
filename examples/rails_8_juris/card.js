import { html, cn } from '@/lib/juris'

export function Card({ children, className = '' }) {
  return html`
    <div class="${cn('bg-white rounded-lg border border-gray-200 shadow-sm', className)}">
      ${children}
    </div>
  `
}

export function CardHeader({ children, className = '' }) {
  return html`
    <div class="${cn('px-6 py-4 border-b border-gray-200', className)}">
      ${children}
    </div>
  `
}

export function CardTitle({ children, className = '' }) {
  return html`
    <h3 class="${cn('text-lg font-semibold text-gray-900', className)}">
      ${children}
    </h3>
  `
}

export function CardDescription({ children, className = '' }) {
  return html`
    <p class="${cn('text-sm text-gray-500 mt-1', className)}">
      ${children}
    </p>
  `
}

export function CardContent({ children, className = '' }) {
  return html`
    <div class="${cn('px-6 py-4', className)}">
      ${children}
    </div>
  `
}

export function CardFooter({ children, className = '' }) {
  return html`
    <div class="${cn('px-6 py-4 border-t border-gray-200 bg-gray-50', className)}">
      ${children}
    </div>
  `
}
