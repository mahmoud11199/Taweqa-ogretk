var SUPABASE_URL = 'https://hhuiseftzbqssswnuwrv.supabase.co';
var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhodWlzZWZ0emJxc3Nzd251d3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMDE5NjEsImV4cCI6MjA5NjY3Nzk2MX0.HSfq7SDEnuoK6ERAV_mINDN49ZJntiBRkVc8L7RsAYY';
var supabase = null;
try {
  if (window.supabase) {
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
} catch (e) { console.warn('Supabase unavailable:', e); }

var currentUser = null, currentProfile = null;
var loadingScreen = document.getElementById('loading-screen');
var landingPage = document.getElementById('landing-page');
var authContainer = document.getElementById('auth-container');
var driverApp = document.getElementById('driver-app');
var passengerApp = document.getElementById('passenger-app');
