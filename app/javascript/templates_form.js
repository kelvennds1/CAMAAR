const setupTemplateForm = () => {
  const formContainer = document.querySelector('[data-template-form="container"]');
  if (!formContainer) return;

  const questionsContainer = formContainer.querySelector('[data-template-form-target="questions"]');
  const blueprint = formContainer.querySelector('#question-fields-template');
  const addButton = formContainer.querySelector('[data-action="add-question"]');

  if (!questionsContainer || !blueprint || !addButton) return;

  const toggleExtras = (block) => {
    const currentType = block.querySelector('[data-testid="question-type"]')?.value;
    block.querySelectorAll('[data-question-extra]').forEach((element) => {
      element.style.display = element.dataset.questionExtra === currentType ? '' : 'none';
    });
  };

  const updatePositions = () => {
    const activeBlocks = Array.from(questionsContainer.querySelectorAll('[data-testid="question-block"]'))
      .filter((block) => block.dataset.removed !== 'true');

    activeBlocks.forEach((block, index) => {
      const positionInput = block.querySelector('[data-testid="question-position"]');
      const indexLabel = block.querySelector('[data-testid="question-index"]');
      if (positionInput) positionInput.value = index + 1;
      if (indexLabel) indexLabel.textContent = index + 1;
    });
  };

  const handleRemovalToggle = (block) => {
    const checkbox = block.querySelector('[data-testid="question-remove-checkbox"]');
    if (!checkbox) return;

    checkbox.addEventListener('change', () => {
      if (checkbox.checked) {
        block.dataset.removed = 'true';
        block.style.display = 'none';
      } else {
        block.dataset.removed = 'false';
        block.style.display = '';
      }
      updatePositions();
    });
  };

  const setupBlock = (block) => {
    block.dataset.removed = 'false';
    const typeSelect = block.querySelector('[data-testid="question-type"]');
    if (typeSelect) {
      typeSelect.addEventListener('change', () => toggleExtras(block));
    }
    toggleExtras(block);
    handleRemovalToggle(block);
  };

  questionsContainer.querySelectorAll('[data-testid="question-block"]').forEach(setupBlock);
  updatePositions();

  addButton.addEventListener('click', (event) => {
    event.preventDefault();
    const html = blueprint.innerHTML.replace(/NEW_RECORD/g, Date.now().toString());
    const wrapper = document.createElement('div');
    wrapper.innerHTML = html.trim();
    const block = wrapper.firstElementChild;
    questionsContainer.appendChild(block);
    setupBlock(block);
    updatePositions();
  });

  questionsContainer.addEventListener('click', (event) => {
    const button = event.target.closest('[data-action="remove-question"]');
    if (!button) return;
    event.preventDefault();
    const block = button.closest('[data-testid="question-block"]');
    if (!block) return;
    const checkbox = block.querySelector('[data-testid="question-remove-checkbox"]');
    if (checkbox && !checkbox.checked) {
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));
    }
  });
};

const initTemplateForm = () => {
  setupTemplateForm();
};

document.addEventListener('turbo:load', initTemplateForm);
document.addEventListener('DOMContentLoaded', initTemplateForm);
