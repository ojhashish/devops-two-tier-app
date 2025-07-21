// frontend/cypress/e2e/app.cy.ts
describe('Two-Tier App E2E Tests', () => {
  it('should display backend health and message', () => {
    cy.visit('http://localhost:3001'); 
    cy.contains('My Two-Tier App').should('be.visible');
    cy.contains('Backend Health: healthy', { timeout: 10000 }).should('be.visible');
    cy.contains('Backend Message: Hello from the backend!', { timeout: 10000 }).should('be.visible');
  });
});
