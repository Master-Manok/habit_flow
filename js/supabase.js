// ─────────────────────────────────────────────────────────────
//  HabitFlow — Supabase client config
//  js/supabase.js
//  Replace SUPABASE_URL and SUPABASE_ANON_KEY with your values
//  from: Supabase Dashboard → Settings → API
// ─────────────────────────────────────────────────────────────

const SUPABASE_URL      = 'https://mikrmkicllqwsnzqtgwf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pa3Jta2ljbGxxd3NuenF0Z3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwOTIzMDEsImV4cCI6MjA5MjY2ODMwMX0.2xjCvhiEE5uomIU_acdo6iRzklPRjdCXKxPWlly-45Q';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helper: get currently logged-in user (null if not logged in)
async function getCurrentUser() {
  const { data: { user } } = await sb.auth.getUser();
  return user;
}

// Helper: get profile row for a user id
async function getProfile(userId) {
  const { data, error } = await sb
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data;
}

// Redirect to login if not authenticated
async function requireAuth() {
  const user = await getCurrentUser();
  if (!user) { window.location.href = 'index.html'; return null; }
  return user;
}

// Redirect to app if already authenticated
async function redirectIfAuth(dest = 'app.html') {
  const user = await getCurrentUser();
  if (user) window.location.href = dest;
}
