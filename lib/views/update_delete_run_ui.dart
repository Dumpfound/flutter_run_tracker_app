import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_run_tracker_app/models/run_model.dart';

class UpdateDeleteRunUI extends StatefulWidget {
  final RunModel run;

  const UpdateDeleteRunUI({super.key, required this.run});

  @override
  State<UpdateDeleteRunUI> createState() => _UpdateDeleteRunUIState();
}

class _UpdateDeleteRunUIState extends State<UpdateDeleteRunUI> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController runWhereCtrl;
  late TextEditingController runPersonCtrl;
  late TextEditingController runDistanceCtrl;

  File? selectedImage;
  String? currentImageUrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    runWhereCtrl = TextEditingController(text: widget.run.runWhere);
    runPersonCtrl = TextEditingController(text: widget.run.runPerson);
    runDistanceCtrl = TextEditingController(text: widget.run.runDistance.toString());
    currentImageUrl = widget.run.runImageUrl;
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> updateData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      String? imageUrl = currentImageUrl;

      // ถ้ามีรูปใหม่ → อัปโหลดใหม่
      if (selectedImage != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        final bytes = await selectedImage!.readAsBytes();

        await supabase.storage.from('run_bk').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        imageUrl = supabase.storage.from('run_bk').getPublicUrl(fileName);

        // ลบรูปเก่า (ถ้ามี)
        if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
          try {
            final oldFileName = currentImageUrl!.split('/').last;
            await supabase.storage.from('run_bk').remove([oldFileName]);
          } catch (_) {}
        }
      }

      await supabase.from('run_tb').update({
        'runWhere': runWhereCtrl.text.trim(),
        'runPerson': runPersonCtrl.text.trim(),
        'runDistance': int.parse(runDistanceCtrl.text.trim()),
        'runImageUrl': imageUrl,
      }).eq('id', widget.run.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> deleteData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSaving = true);

    try {
      // ลบรูปใน Storage (ถ้ามี)
      if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
        try {
          final fileName = currentImageUrl!.split('/').last;
          await supabase.storage.from('run_bk').remove([fileName]);
        } catch (_) {}
      }

      // ลบข้อมูลใน Database
      await supabase.from('run_tb').delete().eq('id', widget.run.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        title: const Text('Run Tracker (แก้ไข/ลบ)', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 50, left: 40, right: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // รูปภาพ
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('ถ่ายรูป'),
                              onTap: () {
                                Navigator.pop(context);
                                pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('เลือกจากแกลเลอรี่'),
                              onTap: () {
                                Navigator.pop(context);
                                pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.width * 0.5,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                currentImageUrl!,
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: MediaQuery.of(context).size.width * 0.5,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.add_a_photo,
                                  size: MediaQuery.of(context).size.width * 0.45,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: MediaQuery.of(context).size.width * 0.45,
                              color: Colors.grey,
                            ),
                ),
                const SizedBox(height: 30),

                // วิ่งที่ไหน
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งที่ไหน', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runWhereCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'กรุณากรอกสถานที่วิ่ง';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // วิ่งกับใคร
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งกับใคร', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runPersonCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'กรุณากรอกว่าวิ่งกับใคร';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ระยะทาง
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ระยะทาง (กิโลเมตร)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runDistanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'กรุณากรอกระยะทาง';
                    if (int.tryParse(value.trim()) == null) return 'กรุณากรอกเป็นตัวเลขเท่านั้น';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // ปุ่มบันทึก
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : updateData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),

                // ปุ่มลบ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : deleteData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ลบข้อมูล', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
