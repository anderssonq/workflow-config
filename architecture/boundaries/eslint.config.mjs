// One flat config for the whole workspace. Packages do not define their own:
// per-package configs diverge silently, and the divergence surfaces only when a
// file moves between packages and starts failing a rule it never saw.
//
// Composition order matters. Prettier goes last so it can turn off the stylistic
// rules everything above it turned on.

import eslint from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import prettier from 'eslint-config-prettier'
import globals from 'globals'

// The three layers over the kernel. Adding one is a one-word change here.
const LAYERS = ['site', 'auth', 'app']
const KERNEL = ['components', 'hooks', 'lib']

// A layer may not import another layer. The public surface must render with the
// API unreachable; one import from the authenticated product puts a query behind
// it and breaks exactly the property that layer exists to have.
const layerRules = LAYERS.map((layer) => ({
  files: [`apps/web/src/${layer}/**/*.{ts,tsx}`],
  ignores: ['**/*.test.{ts,tsx}'],
  rules: {
    'no-restricted-imports': [
      'error',
      {
        patterns: LAYERS.filter((other) => other !== layer).map((other) => ({
          group: [`@/${other}`, `@/${other}/*`, `../${other}/*`, `../../${other}/*`],
          message:
            `src/${layer} must not import src/${other}. ` +
            `If the code is shared, it belongs in the kernel (${KERNEL.join(', ')}).`,
        })),
      },
    ],
  },
}))

// The kernel imports no layer. A shared component reaching into a layer for a
// type drags that layer's screens, its router, and everything the router touches
// into every bundle the kernel is in.
const kernelRule = {
  files: KERNEL.map((dir) => `apps/web/src/${dir}/**/*.{ts,tsx}`),
  ignores: ['**/*.test.{ts,tsx}'],
  rules: {
    'no-restricted-imports': [
      'error',
      {
        patterns: LAYERS.map((layer) => ({
          group: [`@/${layer}`, `@/${layer}/*`, `../${layer}/*`, `../../${layer}/*`],
          message:
            `The kernel must not import src/${layer}. ` +
            `Invert the dependency: the layer consumes the kernel, never the reverse.`,
        })),
      },
    ],
  },
}

export default tseslint.config(
  { ignores: ['**/dist/**', '**/build/**', '**/coverage/**', '**/.next/**'] },

  eslint.configs.recommended,
  ...tseslint.configs.recommended,

  // Node + test globals for everything that runs outside a browser.
  {
    files: ['apps/api/**/*.ts', 'packages/**/*.ts'],
    languageOptions: { globals: { ...globals.node, ...globals.jest } },
  },
  {
    files: ['scripts/**/*.mjs'],
    languageOptions: { globals: globals.node },
  },

  // Browser globals and hook rules for the web app.
  {
    files: ['apps/web/**/*.{ts,tsx}'],
    languageOptions: { globals: globals.browser },
    plugins: { 'react-hooks': reactHooks },
    rules: reactHooks.configs.recommended.rules,
  },

  ...layerRules,
  kernelRule,

  prettier,
)
