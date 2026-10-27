(function() {
    'use strict';

    const pathSegments = window.location.pathname.split('/').filter(Boolean);
    const repoName = pathSegments.length > 0 ? pathSegments[0] : 'ecs';

    const possibleUrls = [
        `/${repoName}/versions.json`,
        '../versions.json',
        '../../versions.json',
        '../../../versions.json',
        './versions.json'
    ];

    async function loadVersions() {
        for (const url of possibleUrls) {
            try {
                const response = await fetch(url);
                if (response.ok) {
                    return await response.json();
                }
            } catch (e) {
                // try next
            }
        }
        return null;
    }

    async function init() {
        const data = await loadVersions();
        if (!data) return;

        let currentVersion = '';
        if (pathSegments.length > 1) {
            currentVersion = pathSegments[1];
        }

        if (document.getElementById('fireblade-version-picker-container')) return;

        const container = document.createElement('div');
        container.id = 'fireblade-version-picker-container';
        container.style.cssText = `
            display: inline-flex;
            align-items: center;
            margin-left: 12px;
            margin-right: 12px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            font-size: 13px;
            z-index: 1000;
        `;

        const select = document.createElement('select');
        select.id = 'fireblade-version-select';
        select.style.cssText = `
            background-color: var(--color-background, #f5f5f7);
            color: var(--color-text, #1d1d1f);
            border: 1px solid var(--color-border, #d2d2d7);
            border-radius: 6px;
            padding: 4px 8px;
            font-size: 13px;
            font-family: inherit;
            cursor: pointer;
            outline: none;
        `;

        if (data.versions) {
            data.versions.forEach(v => {
                const opt = document.createElement('option');
                opt.value = v.path;
                opt.textContent = v.label;
                if (v.name === currentVersion || (currentVersion === '' && v.name === data.latest)) {
                    opt.selected = true;
                }
                select.appendChild(opt);
            });
        }

        const allOpt = document.createElement('option');
        allOpt.value = 'all-versions';
        allOpt.textContent = 'All Versions...';
        select.appendChild(allOpt);

        select.addEventListener('change', (e) => {
            const val = e.target.value;
            if (val === 'all-versions') {
                window.location.href = `/${repoName}/versions/`;
                return;
            }
            const matched = data.versions.find(v => v.path === val);
            const version = matched ? matched.name : '';
            const targetPath = `/${repoName}/${val}`;

            window.dispatchEvent(new CustomEvent('version-change', {
                detail: { version: version, path: targetPath }
            }));

            window.location.href = targetPath;
        });

        container.appendChild(select);

        const navBar = document.querySelector('header') || document.querySelector('nav') || document.querySelector('.nav-bar') || document.querySelector('.nav-wrapper');
        if (navBar) {
            const actionsContainer = navBar.querySelector('.nav-actions') || navBar.querySelector('.links') || navBar;
            actionsContainer.appendChild(container);
        } else {
            container.style.cssText += `
                position: fixed;
                top: 10px;
                right: 20px;
                background: var(--color-background, rgba(255,255,255,0.9));
                backdrop-filter: blur(10px);
                padding: 4px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            `;
            document.body.appendChild(container);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
