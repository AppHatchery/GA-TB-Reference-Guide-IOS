function switchTab(tabIndex) {
  document.querySelectorAll('.tab').forEach(tab => {
      tab.classList.remove('active-tab');
  });
  document.querySelectorAll('.tab-content').forEach(content => {
      content.classList.remove('active-tab');
  });

  document.querySelectorAll('.tab')[tabIndex].classList.add('active-tab');
  document.getElementById(`tab-content${tabIndex}`).classList.add('active-tab');
}