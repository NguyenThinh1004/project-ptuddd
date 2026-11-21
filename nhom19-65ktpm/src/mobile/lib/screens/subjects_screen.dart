import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  void _showAddSubjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm môn học / học phần'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ví dụ: Tiếng Anh chuyên ngành'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<StudyProvider>().addSubject(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, String subjectId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ghi chú học tập'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập ghi chú...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<StudyProvider>().addNoteToSubject(subjectId, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Môn Học, Tài Liệu & Ghi Chú')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.subjects.length,
        itemBuilder: (context, i) {
          final sub = provider.subjects[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${sub.materials.length} tài liệu • ${sub.notes.length} ghi chú'),
              children: [
                ...sub.materials.map((m) => ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(m),
                      subtitle: const Text('Tài liệu học tập'),
                    )),
                ...sub.notes.map((n) => ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: Text(n),
                      subtitle: const Text('Ghi chú'),
                    )),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => _showAddNoteDialog(context, sub.id),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Thêm ghi chú'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
