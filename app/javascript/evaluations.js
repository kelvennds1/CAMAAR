const setupEvaluationsForm = () => {
  const controller = document.querySelector('[data-controller="evaluations"]');
  if (!controller) return;

  const container = controller.querySelector('[data-evaluations-target="container"]');
  const counter = controller.querySelector('[data-evaluations-target="counter"]');
  const selectAllBtn = controller.querySelector('[data-action="evaluations#selectAll"]');
  const clearAllBtn = controller.querySelector('[data-action="evaluations#clearAll"]');

  const checkboxSelector = 'input[type="checkbox"][name="avaliacao_batch[turma_ids][]"]';

  const selectedLabel = (count) => {
    if (count === 0) return 'Nenhuma turma selecionada';
    if (count === 1) return '1 turma selecionada';
    return `${count} turmas selecionadas`;
  };

  const updateCounter = () => {
    if (!counter) return;
    const count = container ? container.querySelectorAll(`${checkboxSelector}:checked`).length : 0;
    counter.textContent = selectedLabel(count);
  };

  const toggleAll = (checked) => {
    if (!container) return;
    container.querySelectorAll(checkboxSelector).forEach((checkbox) => {
      checkbox.checked = checked;
    });
    updateCounter();
  };

  selectAllBtn?.addEventListener('click', (event) => {
    event.preventDefault();
    toggleAll(true);
  });

  clearAllBtn?.addEventListener('click', (event) => {
    event.preventDefault();
    toggleAll(false);
  });

  container?.addEventListener('change', (event) => {
    if (event.target.matches(checkboxSelector)) {
      updateCounter();
    }
  });

  updateCounter();
};

const initEvaluationsForm = () => {
  setupEvaluationsForm();
};

['turbo:load', 'DOMContentLoaded'].forEach((eventName) => {
  document.addEventListener(eventName, initEvaluationsForm);
});
