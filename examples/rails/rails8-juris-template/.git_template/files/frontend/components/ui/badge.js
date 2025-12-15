import { html, cn } from '@/lib/juris'

const variants = {
  default: 'bg-blue-100 text-blue-800',
  secondary: 'bg-gray-100 text-gray-800',
  success: 'bg-green-100 text-green-800',
  warning: 'bg-yellow-100 text-yellow-800',
  danger: 'bg-red-100 text-red-800',
  info: 'bg-cyan-100 text-cyan-800'
}

export function Badge({ 
  children, 
  variant = 'default',
  className = ''
}) {
  const variantClass = variants[variant] || variants.default
  
  return html`
    <span class="${cn(
      'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
      variantClass,
      className
    )}">
      ${children}
    </span>
  `
}
