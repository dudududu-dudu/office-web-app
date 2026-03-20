(function () {
  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  ready(function () {
    var openBtns = document.querySelectorAll('[data-open-consult]');
    var closeBtns = document.querySelectorAll('[data-close-consult]');
    var dialog = document.getElementById('consult-dialog');

    if (!dialog) return;

    function openDialog(e) {
      if (e) e.preventDefault();
      if (typeof dialog.showModal === 'function') {
        dialog.showModal();
      } else {
        dialog.classList.add('is-open');
      }
    }

    function closeDialog(e) {
      if (e) e.preventDefault();
      if (typeof dialog.close === 'function') {
        dialog.close();
      } else {
        dialog.classList.remove('is-open');
      }
    }

    openBtns.forEach(function (btn) {
      btn.addEventListener('click', openDialog);
    });

    closeBtns.forEach(function (btn) {
      btn.addEventListener('click', closeDialog);
    });

    dialog.addEventListener('click', function (e) {
      // 点击遮罩关闭（dialog 本体以外）
      var rect = dialog.getBoundingClientRect();
      var inDialog =
        rect.top <= e.clientY &&
        e.clientY <= rect.bottom &&
        rect.left <= e.clientX &&
        e.clientX <= rect.right;

      if (!inDialog) closeDialog(e);
    });
  });
})();
