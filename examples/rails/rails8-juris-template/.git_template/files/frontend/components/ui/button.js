import { html, cn } from '@/lib/juris'

const variants = {
  default: 'bg-blue-600 text-white hover:bg-blue-700',
  secondary: 'bg-gray-600 text-white hover:bg-gray-700',
  outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50',
  ghost: 'text-gray-700 hover:bg-gray-100',
  link: 'text-blue-600 underline-offset-4 hover:underline',
  destructive: 'bg-red-600 text-white hover:bg-red-700'
}

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg'
}

export function Button({ 
  children, 
  variant = 'default', 
  size = 'md',
  className = '',
  onClick,
  type = 'button',
  disabled = false
}) {
  const variantClass = variants[variant] || variants.default
  const sizeClass = sizes[size] || sizes.md
  
  return html`
    <button
      type="${type}"
      class="${cn(
        'inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed',
        variantClass,
        sizeClass,
        className
      )}"
      ${disabled ? 'disabled' : ''}
      ${onClick ? `onclick="${onClick}"` : ''}
    >
      ${children}
    </button>
  `
}
