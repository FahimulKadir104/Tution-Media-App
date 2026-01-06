// Background Service Worker
// Minimal background script for the extension

console.log('Tuition Media Extension loaded');

// Listen for extension installation
chrome.runtime.onInstalled.addListener(() => {
  console.log('Tuition Media Extension installed');
});
