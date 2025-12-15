/**
 * Utility functions for the application
 */

// Format currency
export function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency
  }).format(amount)
}

// Format date
export function formatDate(date, options = {}) {
  const defaultOptions = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }
  
  return new Intl.DateTimeFormat('en-US', { ...defaultOptions, ...options }).format(new Date(date))
}

// Format number
export function formatNumber(number, decimals = 0) {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  }).format(number)
}

// Debounce function
export function debounce(func, wait) {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

// Throttle function
export function throttle(func, limit) {
  let inThrottle
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

// Class names helper (similar to clsx)
export function cn(...classes) {
  return classes
    .flat()
    .filter(Boolean)
    .join(' ')
}

// Slugify string
export function slugify(str) {
  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

// Truncate string
export function truncate(str, length = 50, suffix = '...') {
  if (str.length <= length) return str
  return str.substring(0, length - suffix.length) + suffix
}

// Deep clone object
export function deepClone(obj) {
  return JSON.parse(JSON.stringify(obj))
}

// Check if object is empty
export function isEmpty(obj) {
  return Object.keys(obj).length === 0
}

// Get nested property safely
export function get(obj, path, defaultValue = undefined) {
  const keys = path.split('.')
  let result = obj
  
  for (const key of keys) {
    if (result?.[key] === undefined) {
      return defaultValue
    }
    result = result[key]
  }
  
  return result
}
