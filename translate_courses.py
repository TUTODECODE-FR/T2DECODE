import json
import re
import os
from deep_translator import GoogleTranslator

translator = GoogleTranslator(source='fr', target='en')

def translate_safe(text):
    if not text or not text.strip():
        return text
    
    # Extract code blocks to avoid translating code
    code_blocks = []
    def replacer(match):
        code_blocks.append(match.group(0))
        return f'__CODE_BLOCK_{len(code_blocks)-1}__'
        
    # Replace markdown code blocks
    text_no_code = re.sub(r'```.*?```', replacer, text, flags=re.DOTALL)
    
    # Replace inline code
    text_no_code = re.sub(r'`[^`\n]+`', replacer, text_no_code)
    
    # Translate in chunks if too long (Google translate limit is 5000 chars)
    translated = ""
    for chunk in [text_no_code[i:i+4500] for i in range(0, len(text_no_code), 4500)]:
        try:
            translated += translator.translate(chunk)
        except Exception as e:
            print(f"Error translating chunk: {e}")
            translated += chunk

    # Restore code blocks
    for i, code in enumerate(code_blocks):
        translated = translated.replace(f'__CODE_BLOCK_{i}__', code)
        
    return translated

def main():
    print("Loading courses.json...")
    with open('assets/courses.json', 'r', encoding='utf-8') as f:
        courses = json.load(f)

    # Dictionary for fixed translations
    level_map = {
        "Débutant": "Beginner",
        "Intermédiaire": "Intermediate",
        "Avancé": "Advanced",
        "Expert": "Expert"
    }

    print("Translating courses...")
    for i, course in enumerate(courses):
        print(f"Translating course {i+1}/{len(courses)}: {course.get('title')}")
        course['title'] = translate_safe(course.get('title', ''))
        course['description'] = translate_safe(course.get('description', ''))
        
        if course.get('level') in level_map:
            course['level'] = level_map[course['level']]
            
        course['category'] = translate_safe(course.get('category', ''))
        
        for j, chapter in enumerate(course.get('content', [])):
            print(f"  Chapter {j+1}: {chapter.get('title')}")
            chapter['title'] = translate_safe(chapter.get('title', ''))
            
            # Content is a huge markdown string
            content = chapter.get('content', '')
            if content:
                chapter['content'] = translate_safe(content)

    os.makedirs('assets/courses', exist_ok=True)
    
    print("Saving courses_en.json...")
    with open('assets/courses/courses_en.json', 'w', encoding='utf-8') as f:
        json.dump(courses, f, ensure_ascii=False, indent=2)

    print("Copying original to courses_fr.json...")
    import shutil
    shutil.copy('assets/courses.json', 'assets/courses/courses_fr.json')
    
    # We remove the original to respect the new architecture
    os.remove('assets/courses.json')
    
    print("Translation complete!")

if __name__ == '__main__':
    main()
