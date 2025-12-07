const setupSigaaImports = () => {
  const updateForm = document.querySelector('.sigaa-imports-page__update-form');
  if (!updateForm) return;

  const submitButton = updateForm.querySelector('button[type="submit"], input[type="submit"]');
  const originalButtonText = submitButton?.textContent || submitButton?.value;

  // Criar overlay de loading
  const createLoadingOverlay = () => {
    const overlay = document.createElement('div');
    overlay.className = 'api-simulation-overlay';
    overlay.innerHTML = `
      <div class="api-simulation-modal">
        <div class="api-simulation-header">
          <h3>🔄 Sincronizando com SIGAA</h3>
        </div>
        <div class="api-simulation-content">
          <div class="api-simulation-steps">
            <div class="api-step" data-step="connect">
              <div class="api-step__icon">🔌</div>
              <div class="api-step__content">
                <div class="api-step__title">Conectando ao SIGAA...</div>
                <div class="api-step__description">Estabelecendo conexão com a API</div>
              </div>
              <div class="api-step__status"></div>
            </div>
            <div class="api-step" data-step="fetch-classes">
              <div class="api-step__icon">📚</div>
              <div class="api-step__content">
                <div class="api-step__title">Buscando dados de matérias e turmas...</div>
                <div class="api-step__description">Obtendo classes.json</div>
              </div>
              <div class="api-step__status"></div>
            </div>
            <div class="api-step" data-step="fetch-members">
              <div class="api-step__icon">👥</div>
              <div class="api-step__content">
                <div class="api-step__title">Buscando dados de participantes...</div>
                <div class="api-step__description">Obtendo class_members.json</div>
              </div>
              <div class="api-step__status"></div>
            </div>
            <div class="api-step" data-step="process">
              <div class="api-step__icon">⚙️</div>
              <div class="api-step__content">
                <div class="api-step__title">Processando dados...</div>
                <div class="api-step__description">Atualizando base de dados</div>
              </div>
              <div class="api-step__status"></div>
            </div>
            <div class="api-step" data-step="complete">
              <div class="api-step__icon">✅</div>
              <div class="api-step__content">
                <div class="api-step__title">Sincronização concluída!</div>
                <div class="api-step__description">Redirecionando...</div>
              </div>
              <div class="api-step__status"></div>
            </div>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    return overlay;
  };

  // Atualizar status do step
  const updateStep = (stepName, status) => {
    const step = document.querySelector(`[data-step="${stepName}"]`);
    if (!step) return;

    const statusEl = step.querySelector('.api-step__status');
    step.classList.remove('api-step--pending', 'api-step--active', 'api-step--complete');
    
    switch (status) {
      case 'pending':
        step.classList.add('api-step--pending');
        statusEl.textContent = '';
        break;
      case 'active':
        step.classList.add('api-step--active');
        statusEl.innerHTML = '<div class="spinner"></div>';
        break;
      case 'complete':
        step.classList.add('api-step--complete');
        statusEl.textContent = '✓';
        break;
    }
  };

  // Simular processo de API
  const simulateApiCall = async () => {
    const overlay = createLoadingOverlay();
    
    // Desabilitar botão
    if (submitButton) {
      submitButton.disabled = true;
      if (submitButton.tagName === 'INPUT') {
        submitButton.value = 'Sincronizando...';
      } else {
        submitButton.textContent = 'Sincronizando...';
      }
    }

    try {
      // Step 1: Conectar
      updateStep('connect', 'active');
      await new Promise(resolve => setTimeout(resolve, 800));

      // Step 2: Buscar classes
      updateStep('connect', 'complete');
      updateStep('fetch-classes', 'active');
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Step 3: Buscar members
      updateStep('fetch-classes', 'complete');
      updateStep('fetch-members', 'active');
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Step 4: Processar
      updateStep('fetch-members', 'complete');
      updateStep('process', 'active');
      await new Promise(resolve => setTimeout(resolve, 1200));

      // Step 5: Completar
      updateStep('process', 'complete');
      updateStep('complete', 'active');
      await new Promise(resolve => setTimeout(resolve, 500));

      // Submeter o formulário após a simulação
      updateForm.submit();
    } catch (error) {
      console.error('Erro na simulação:', error);
      overlay.remove();
      if (submitButton) {
        submitButton.disabled = false;
        if (submitButton.tagName === 'INPUT') {
          submitButton.value = originalButtonText;
        } else {
          submitButton.textContent = originalButtonText;
        }
      }
    }
  };

  // Interceptar submit do formulário
  updateForm.addEventListener('submit', (event) => {
    // Verificar se já está em processo
    if (submitButton?.disabled) {
      event.preventDefault();
      return false;
    }

    // Pedir confirmação antes de iniciar a simulação
    const confirmed = window.confirm(
      'Deseja atualizar a base de dados com os arquivos classes.json e class_members.json do repositório? Esta ação irá atualizar registros existentes e adicionar novos.'
    );

    if (confirmed) {
      event.preventDefault();
      simulateApiCall();
    } else {
      event.preventDefault();
    }
    
    return false;
  });
};

const initSigaaImports = () => {
  setupSigaaImports();
};

['turbo:load', 'DOMContentLoaded'].forEach((eventName) => {
  document.addEventListener(eventName, initSigaaImports);
});

