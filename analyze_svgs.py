#!/usr/bin/env python3
"""
Analyze SVG files in the Postings directory and generate metadata with tags.
This script extracts text, shapes, and visual elements to create searchable tags.
"""

import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path
import json

def extract_text_from_svg(svg_path):
    """Extract all text content from an SVG file."""
    try:
        tree = ET.parse(svg_path)
        root = tree.getroot()

        # Handle SVG namespace
        namespaces = {'svg': 'http://www.w3.org/2000/svg'}

        texts = []
        for text_elem in root.findall('.//svg:text', namespaces):
            text_content = ''.join(text_elem.itertext()).strip()
            if text_content:
                texts.append(text_content)

        # Also try without namespace (some SVGs don't use it)
        for text_elem in root.findall('.//text'):
            text_content = ''.join(text_elem.itertext()).strip()
            if text_content and text_content not in texts:
                texts.append(text_content)

        return texts
    except Exception as e:
        print(f"Error reading {svg_path}: {e}")
        return []

def analyze_svg_shapes(svg_path):
    """Analyze shapes in SVG to determine icon type."""
    try:
        tree = ET.parse(svg_path)
        root = tree.getroot()

        # Count different shape types
        shapes = {
            'circle': len(root.findall('.//{http://www.w3.org/2000/svg}circle')) + len(root.findall('.//circle')),
            'rect': len(root.findall('.//{http://www.w3.org/2000/svg}rect')) + len(root.findall('.//rect')),
            'path': len(root.findall('.//{http://www.w3.org/2000/svg}path')) + len(root.findall('.//path')),
            'polygon': len(root.findall('.//{http://www.w3.org/2000/svg}polygon')) + len(root.findall('.//polygon')),
            'line': len(root.findall('.//{http://www.w3.org/2000/svg}line')) + len(root.findall('.//line')),
        }

        return shapes
    except Exception as e:
        print(f"Error analyzing shapes in {svg_path}: {e}")
        return {}

def generate_tags(filename, texts, shapes):
    """Generate searchable tags based on file content."""
    tags = set()

    # Extract keywords from text content
    for text in texts:
        # Split on spaces and common delimiters
        words = re.findall(r'\b[a-zA-Z]{3,}\b', text.lower())
        tags.update(words)

    # Add shape-based tags
    if shapes.get('circle', 0) > 5:
        tags.add('circular')
    if shapes.get('rect', 0) > 5:
        tags.add('rectangular')
    if shapes.get('path', 0) > 20:
        tags.add('complex')

    # Common radiological posting keywords to look for
    keywords = [
        'caution', 'radiation', 'radioactive', 'area', 'high', 'contamination',
        'airborne', 'danger', 'restricted', 'controlled', 'warning', 'hotspot',
        'rba', 'protective', 'clothing', 'dosimetry', 'survey'
    ]

    combined_text = ' '.join(texts).lower()
    for keyword in keywords:
        if keyword in combined_text:
            tags.add(keyword)

    return sorted(list(tags))

def analyze_postings_directory(postings_dir):
    """Analyze all SVG files in the Postings directory."""
    postings_path = Path(postings_dir)
    svg_files = sorted(postings_path.glob('*.svg'))

    results = []

    for svg_file in svg_files:
        print(f"Analyzing {svg_file.name}...")

        texts = extract_text_from_svg(svg_file)
        shapes = analyze_svg_shapes(svg_file)
        tags = generate_tags(svg_file.name, texts, shapes)

        # Create a descriptive name from text content
        if texts:
            # Use first substantial text as display name
            display_name = texts[0] if texts[0] else svg_file.stem
            if len(display_name) > 50:
                display_name = display_name[:47] + "..."
        else:
            display_name = svg_file.stem

        result = {
            'filename': svg_file.name,
            'display_name': display_name,
            'texts': texts[:5],  # First 5 text elements
            'tags': tags,
            'shape_count': sum(shapes.values())
        }

        results.append(result)

    return results

def main():
    postings_dir = 'assets/Postings'

    if not os.path.exists(postings_dir):
        print(f"Error: Directory {postings_dir} not found")
        return

    print(f"Analyzing SVG files in {postings_dir}...")
    results = analyze_postings_directory(postings_dir)

    # Save results to JSON
    output_file = 'postings_metadata.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\nAnalysis complete! Results saved to {output_file}")
    print(f"Total files analyzed: {len(results)}")

    # Print summary
    print("\nSample results:")
    for result in results[:5]:
        print(f"\n{result['filename']}:")
        print(f"  Display Name: {result['display_name']}")
        print(f"  Tags: {', '.join(result['tags'][:10])}")

if __name__ == '__main__':
    main()
