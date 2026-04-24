// ─── Template Configuration ──────────────────────────────────────────────────
// Este é o ÚNICO arquivo que você precisa editar para personalizar o portal.
// Altere os valores abaixo para cada novo vereador/gabinete.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Logos ───────────────────────────────────────────────────────────────────
// Substitua os arquivos em src/assets/logos/ pelos logos do novo vereador.
// Os nomes dos arquivos devem corresponder aos imports abaixo.
import logoOficial from '../assets/logos/logo_oficial.png';
import logoBranca from '../assets/logos/logo_branca.png';
import logoSplash from '../assets/logos/logo_splash.jpg';

export const TEMPLATE_CONFIG = {
  // ─── Identidade do Gabinete ─────────────────────────────────────────────
  appName: 'Gestão Gabinete',
  vereadorName: 'Tibá',
  vereadorTitle: 'Vereador',
  gabineteSubtitle: 'Portal de Gestão do Gabinete',

  // ─── Textos da Tela de Login ────────────────────────────────────────────
  login: {
    heroTitle: 'Gestão de Gabinete Eficiente',
    heroSubtitle: 'Acesse o portal e gerencie Pessoas, Requerimentos, Ocorrências e Agendas de forma centralizada e ágil.',
    formTitle: 'Acesso ao Sistema',
    formSubtitle: 'Insira suas credenciais para continuar',
    emailPlaceholder: 'assessor@gabinete.gov.br',
  },

  // ─── Textos do Dashboard ────────────────────────────────────────────────
  dashboard: {
    greeting: 'Olá',
    subtitle: 'Aqui está um panorama da base de dados do gabinete.',
  },

  // ─── Splash Screen ─────────────────────────────────────────────────────
  splash: {
    loadingText: 'Carregando sistema...',
  },

  // ─── Cores da Sidebar (classes Tailwind ou HEX) ─────────────────────────
  colors: {
    // Sidebar
    sidebarBg: 'bg-[#03174c]',                 // Background da sidebar (light)
    sidebarBgDark: 'dark:bg-slate-900',         // Background da sidebar (dark)
    sidebarBorder: 'border-white/10',
    sidebarBorderDark: 'dark:border-slate-800',

    // Login left panel gradient
    loginGradientFrom: 'from-[#03174c]',
    loginGradientTo: 'to-[#005b9f]',
    loginPanelBg: 'bg-[#03174c]',

    // Splash progress bar
    splashProgressBar: 'bg-[#00e500]',

    // Accent / botões principais
    accentBg: 'bg-[#005b9f]',
    accentHover: 'hover:bg-[#004a80]',
    accentRing: 'focus:ring-[#005b9f]',
  },

  // ─── Logos (importados acima) ───────────────────────────────────────────
  logos: {
    /** Logo da sidebar no light mode */
    sidebarLight: logoOficial,
    /** Logo da sidebar no dark mode */
    sidebarDark: logoBranca,
    /** Logo grande na tela de login (painel esquerdo) */
    loginHero: logoOficial,
    /** Logo na splash screen */
    splash: logoSplash,
    /** Texto de fallback caso a imagem não carregue */
    fallbackText: 'Gestão Gabinete',
  },

  // ─── Page Title & SEO ──────────────────────────────────────────────────
  pageTitle: 'Gestão Gabinete - Portal Parlamentar',
  metaDescription: 'Portal de gestão de gabinete parlamentar. Gerencie pessoas, requerimentos, agenda e ocorrências.',
} as const;

export type TemplateConfig = typeof TEMPLATE_CONFIG;
