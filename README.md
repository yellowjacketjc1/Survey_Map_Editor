# SurveyMap Editor

A professional Flutter-based web application for creating radiological survey maps.

![Version](https://img.shields.io/badge/version-0.21-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-web-lightgrey.svg)

## Overview

**SurveyMap Editor** is an interactive mapping tool designed to help radiological safety professionals create professional, annotated survey maps quickly and efficiently. Load building floor plans, add survey data, and export publication-ready PDFs.

### Key Features

- 📋 **Complete Survey Documentation** - Auto-generated title cards with survey info and statistics
- 🎯 **Rich Annotation Tools** - Smears, dose rates, boundaries, comments, icons, and postings
- 🛠️ **Powerful Controls** - Undo/redo, zoom, pan, rotate, and keyboard shortcuts
- 💾 **Save/Load Projects** - Continue work later with JSON project files
- 📤 **Professional Export** - High-resolution PDF output suitable for printing

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Chrome browser (for web development)
- Dart SDK (included with Flutter)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Survey_Map_Editor.git
cd Survey_Map_Editor
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d chrome
```

The application will open in your Chrome browser.

### Building for Production

To build a production web version:

```bash
flutter build web
```

The output will be in the `build/web` directory.

## Usage

### Quick Start

1. **Load a Map** - Browse pre-configured maps or upload your own PDF
2. **Add Annotations** - Use tools in the right sidebar
3. **Export** - Click "Export PDF" in the top toolbar

See the [User Guide](USER_GUIDE.md) for comprehensive documentation.

### Main Features

#### Annotation Tools

- **Removable Smears** - Numbered sample locations
- **Dose Rates** - Gamma (γ) or neutron (n) measurements with units
- **Boundaries** - Draw contamination zones and controlled areas
- **Comments/Notes** - Text annotations
- **Icon Library** - Material Design icons for equipment
- **Radiological Postings** - Official posting signs

#### Controls

- **Top Toolbar** - Undo/redo, rotation, zoom, save/load, export
- **Keyboard Shortcuts** - Esc (exit tool), Delete (remove), R (rotate)
- **Mouse Controls** - Click-drag to pan, wheel to zoom

## Project Structure

```
Survey_Map_Editor/
├── lib/
│   ├── models/          # Data models (annotations, survey data)
│   ├── screens/         # Main application screens
│   ├── services/        # Business logic (PDF, export, storage)
│   └── widgets/         # Reusable UI components
├── assets/
│   ├── icons/           # Embedded icon assets
│   ├── Postings/        # Radiological posting images
│   └── Current Maps/    # Building floor plan PDFs
├── web/                 # Web-specific files
├── USER_GUIDE.md        # Complete user documentation
└── pubspec.yaml         # Project dependencies
```

## Technology Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Platform**: Web (Chrome)
- **State Management**: Provider
- **PDF Handling**: pdfx, pdf, printing
- **File Operations**: file_picker
- **Graphics**: flutter_svg, vector_graphics

## Development

### Code Style

This project follows the official Flutter style guide and uses `flutter_lints`.

### Running Tests

```bash
flutter test
```

### Hot Reload

When running in development mode, use `r` in the terminal to hot reload changes.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Roadmap

Planned features:

- [ ] Additional icon libraries (custom symbols)
- [ ] More map templates
- [ ] Export to PNG/JPEG
- [ ] Measurement tools (distance, area)
- [ ] Templates for common survey types
- [ ] Multi-page survey support
- [ ] Collaborative editing
- [ ] Cloud storage integration

## Version History

### Version 0.21 (Current)
- Integrated statistics into title card
- Improved boundary visualization (alternating colors)
- Separate Icon Library and Radiological Postings
- Top toolbar with all controls
- Enhanced text entry fields
- Rotation support for icons and postings
- Keyboard shortcuts (R for rotate, Delete for remove)

### Version 0.20
- Delete with keystroke support
- Smear counting updates
- Esc key for drag/delete mode
- UI refinements

### Version 0.19
- Moving smears/dose rates/icons
- Highlighting on selection
- Keyboard delete functionality

## License

*Add your license information here*

## Authors

- **Your Name** - *Initial work*

## Acknowledgments

- Thanks to all team members who provided feedback during development
- Flutter team for the excellent framework
- All contributors and testers

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact: [your email]
- See [User Guide](USER_GUIDE.md) for documentation

---

**Built with ❤️ using Flutter**
