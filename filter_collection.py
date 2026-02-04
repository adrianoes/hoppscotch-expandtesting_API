#!/usr/bin/env python3
"""Helper para filtrar coleção Hoppscotch e salvar como JSON válido"""

import json
import sys
import os

def filter_collection(collection_path, output_path, pattern):
    """Filtra requests da coleção por padrão de nome"""
    
    with open(collection_path, 'r', encoding='utf-8') as f:
        collection = json.load(f)
    
    filtered_requests = [
        req for req in collection.get('requests', [])
        if pattern(req.get('name', ''))
    ]
    
    if not filtered_requests:
        return False
    
    # Mantém todos os campos de metadata da coleção original
    filtered_collection = {
        key: value for key, value in collection.items()
        if key != 'requests'
    }
    
    filtered_collection['requests'] = filtered_requests
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(filtered_collection, f, ensure_ascii=False, indent=2)
    
    return True

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: filter_collection.py <collection> <output> <filter_type> [filter_value]")
        sys.exit(1)
    
    collection_path = sys.argv[1]
    output_path = sys.argv[2]
    filter_type = sys.argv[3]
    filter_value = sys.argv[4] if len(sys.argv) > 4 else None
    
    if filter_type == 'test_case':
        pattern = lambda name: name.startswith(filter_value)
    elif filter_type == 'multiple':
        codes = filter_value.split(',')
        pattern = lambda name: any(name.startswith(code) for code in codes)
    elif filter_type == 'negative':
        pattern = lambda name: 'bad request' in name.lower() or 'unauthorized' in name.lower()
    elif filter_type == 'positive':
        pattern = lambda name: 'bad request' not in name.lower() and 'unauthorized' not in name.lower()
    else:
        print(f"Unknown filter type: {filter_type}")
        sys.exit(1)
    
    success = filter_collection(collection_path, output_path, pattern)
    sys.exit(0 if success else 1)
