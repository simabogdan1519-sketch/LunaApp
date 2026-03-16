class AppStrings {
  static String _lang = 'English';
  static void setLanguage(String lang) => _lang = lang;
  static final Map<String, Map<String, String>> _s = {
    'home': {'English':'Home','Română':'Acasă','Français':'Accueil','Deutsch':'Startseite','Español':'Inicio','Italiano':'Home','Português':'Início'},
    'settings': {'English':'Settings','Română':'Setări','Français':'Paramètres','Deutsch':'Einstellungen','Español':'Ajustes','Italiano':'Impostazioni','Português':'Configurações'},
    'save': {'English':'Save','Română':'Salvează','Français':'Enregistrer','Deutsch':'Speichern','Español':'Guardar','Italiano':'Salva','Português':'Salvar'},
  };
  static String t(String key) => _s[key]?[_lang] ?? _s[key]?['English'] ?? key;
}
