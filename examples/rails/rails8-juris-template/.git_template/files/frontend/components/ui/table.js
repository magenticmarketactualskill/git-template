import { html, cn } from '@/lib/juris'

export function Table({ children, className = '' }) {
  return html`
    <table class="${cn('min-w-full divide-y divide-gray-200', className)}">
      ${children}
    </table>
  `
}

export function TableHeader({ children, className = '' }) {
  return html`
    <thead class="${cn('bg-gray-50', className)}">
      ${children}
    </thead>
  `
}

export function TableBody({ children, className = '' }) {
  return html`
    <tbody class="${cn('bg-white divide-y divide-gray-200', className)}">
      ${children}
    </tbody>
  `
}

export function TableRow({ children, className = '' }) {
  return html`
    <tr class="${cn('hover:bg-gray-50', className)}">
      ${children}
    </tr>
  `
}

export function TableHead({ children, className = '' }) {
  return html`
    <th class="${cn('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider', className)}">
      ${children}
    </th>
  `
}

export function TableCell({ children, className = '' }) {
  return html`
    <td class="${cn('px-6 py-4 whitespace-nowrap text-sm text-gray-900', className)}">
      ${children}
    </td>
  `
}
