project(
    'QMLogout',
    'cpp',
    version: '0.1.0',
    license: 'BSD-3-Clause',
    meson_version: '>=0.60.0',
    default_options: [
        'cpp_std=c++23',
        'warning_level=2',
        'werror=false',
        'buildtype=release',
    ],
)

cpp_args = []
if host_machine.cpu_family() == 'x86_64'
    cpp_args += ['-march=x86-64-v3']
endif

if get_option('buildtype') == 'release'
    add_project_arguments('-DQT_NO_DEBUG_OUTPUT', language: 'cpp')
endif

qt6 = import('qt6')
qt_deps = dependency(
    'qt6',
    version: '>=6.6',
    modules: [
        'Core',
        'Gui',
        'Qml',
        'Quick',
        'QuickControls2',
    ],
    required: true,
)

kf6coreaddons_dep = dependency('KF6CoreAddons', version: '>=6.0', required: true)
mauikit_dep = dependency('MauiKit4', version: '>=4.0.4', required: true)
mauikit_runtime_dep = declare_dependency(
    dependencies: mauikit_dep,
    link_args: ['-Wl,--no-as-needed'],
)

# LayerShell-Qt has used both pkg-config names across distributions.
dep_layer_shell = dependency('LayerShellQt', required: false)
if not dep_layer_shell.found()
    dep_layer_shell = dependency('LayerShellQtInterface', required: false)
endif
if not dep_layer_shell.found()
    dep_layer_shell = meson.get_compiler('cpp').find_library('LayerShellQtInterface', required: false)
endif
if not dep_layer_shell.found()
    error('LayerShell-Qt was not found. Install liblayershellqtinterface-dev.')
endif

qt6_sources = qt6.preprocess(
    qresources: 'qmlogout.qrc',
    moc_headers: files('src/sessionmanager.h'),
)

executable(
    'qmlogout',
    files(
        'src/main.cpp',
        'src/sessionmanager.cpp',
    ) + qt6_sources,
    dependencies: [
        qt_deps,
        kf6coreaddons_dep,
        mauikit_runtime_dep,
        dep_layer_shell,
    ],
    cpp_args: cpp_args,
    install: true,
)
