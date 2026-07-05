var SUPABASE_URL = 'https://hhuiseftzbqssswnuwrv.supabase.co';
var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhodWlzZWZ0emJxc3Nzd251d3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMDE5NjEsImV4cCI6MjA5NjY3Nzk2MX0.HSfq7SDEnuoK6ERAV_mINDN49ZJntiBRkVc8L7RsAYY';
var supabase = null;

function initSupa() {
  try {
    var c = window.__supa || (window.supabase && window.supabase.createClient);
    if (c) { supabase = c(SUPABASE_URL, SUPABASE_ANON_KEY); return true; }
  } catch(e) { console.warn('Supabase init error:', e); }
  return false;
}

if (!initSupa()) {
  var _r = 0;
  var _t = setInterval(function() {
    if (initSupa() || _r++ > 30) clearInterval(_t);
  }, 100);
}

var currentUser = null, currentProfile = null;
var loadingScreen = document.getElementById('loading-screen');
var landingPage = document.getElementById('landing-page');
var authContainer = document.getElementById('auth-container');
var driverApp = document.getElementById('driver-app');
var passengerApp = document.getElementById('passenger-app');
