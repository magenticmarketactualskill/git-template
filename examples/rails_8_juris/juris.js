/**
 * Juris.js - A minimal JavaScript framework for building reactive UIs
 * Inspired by modern frameworks but keeping it simple with template literals
 */

// State management
let currentState = {}
let stateListeners = new Map()

export function useState(initialValue) {
  const id = Math.random().toString(36).substr(2, 9)
  currentState[id] = initialValue
  
  const setState = (newValue) => {
    currentState[id] = typeof newValue === 'function' 
      ? newValue(currentState[id]) 
      : newValue
    
    // Trigger re-render for listeners
    if (stateListeners.has(id)) {
      stateListeners.get(id).forEach(listener => listener(currentState[id]))
    }
  }
  
  return [() => currentState[id], setState]
}

// Template literal helper
export function html(strings, ...values) {
  return strings.reduce((result, string, i) => {
    const value = values[i] !== undefined ? values[i] : ''
    return result + string + value
  }, '')
}

// Render function
export function render(content, container) {
  if (typeof container === 'string') {
    container = document.querySelector(container)
  }
  
  if (!container) {
    console.error('Container not found')
    return
  }
  
  container.innerHTML = content
}

// Event delegation helper
export function on(element, event, selector, handler) {
  element.addEventListener(event, (e) => {
    if (e.target.matches(selector)) {
      handler(e)
    }
  })
}

// Class name helper
export function cn(...classes) {
  return classes.filter(Boolean).join(' ')
}

// Export all utilities
export default {
  useState,
  html,
  render,
  on,
  cn
}
