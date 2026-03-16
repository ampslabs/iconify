// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://iconify.aditi.cc',
  integrations: [
    starlight({
      title: 'Iconify',
      description: 'A powerful, offline-ready icon SDK for Flutter and Dart.',
      logo: {
        src: './src/assets/logo.svg',
      },
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/ampslabs/iconify_sdk' },
      ],
      // Custom Design
      customCss: ['./src/styles/theme.css'],
      components: {
        Head: './src/components/Head.astro',
        Hero: './src/components/Hero.astro',
      },
      // Expressive Code
      expressiveCode: {
        themes: ['rose-pine-moon'], // Warm dark theme
        styleOverrides: {
          borderRadius: '12px',
          codePaddingInline: '1.5rem',
          codePaddingBlock: '1.5rem',
        }
      },
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Installation', link: '/getting-started/installation' },
            { label: 'Quick Start', link: '/getting-started/quick-start' },
          ],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Production Workflow', link: '/guides/production-workflow' },
            { label: 'Custom Icon Sets', link: '/guides/custom-sets' },
            { label: 'Migration from iconify_flutter', link: '/guides/migration-from-iconify-flutter' },
          ],
        },

        {
          label: 'Reference',
          items: [
            { label: 'Configuration (iconify.yaml)', link: '/reference/configuration' },
            { label: 'Safe Collections', link: '/reference/safe-collections' },
            { label: 'License Guide', link: '/reference/license-guide' },
            { label: 'Performance Baseline', link: '/reference/benchmarks' },
          ],
        },
        {
          label: 'Explanation',
          items: [
            { label: 'Performance Architecture', link: '/explanation/performance' },
            { label: 'Impeller & Rendering', link: '/explanation/impeller' },
          ],
        },
        {
          label: 'Resources',
          items: [
            { label: 'Changelog', link: '/changelog' },
          ],
        },
      ],
    }),
  ],
});
