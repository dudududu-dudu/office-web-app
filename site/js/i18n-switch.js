(function () {
  var STORAGE_KEY = 'site-lang';
  var html = document.documentElement;

  // Restore saved language preference
  var saved = localStorage.getItem(STORAGE_KEY);
  if (saved === 'ja' || saved === 'zh') {
    html.setAttribute('lang', saved === 'ja' ? 'ja' : 'zh-CN');
  }

  function isJa() {
    return html.getAttribute('lang') === 'ja';
  }

  function toggle() {
    var next = isJa() ? 'zh-CN' : 'ja';
    html.setAttribute('lang', next);
    localStorage.setItem(STORAGE_KEY, next === 'ja' ? 'ja' : 'zh');
    updateButtons();
  }

  function updateButtons() {
    var ja = isJa();
    var btns = document.querySelectorAll('.lang-switch');
    btns.forEach(function (btn) {
      btn.setAttribute('aria-label', ja ? '切换到中文' : '日本語に切り替え');
      btn.setAttribute('title', ja ? '切换到中文' : '日本語に切り替え');
    });
  }

  function init() {
    var btns = document.querySelectorAll('.lang-switch');
    btns.forEach(function (btn) {
      btn.addEventListener('click', toggle);
    });
    updateButtons();
  }

  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);
})();
