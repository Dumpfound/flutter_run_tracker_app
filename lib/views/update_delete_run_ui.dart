import 'dart:typed_data';
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

  // ใช้ Uint8List แทน File เพื่อรองรับทั้งมือถือและ Web
  Uint8List? selectedImageBytes;
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

  @override
  void dispose() {
    runWhereCtrl.dispose();
    runPersonCtrl.dispose();
    runDistanceCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200, // ลดขนาดรูปเพื่อประหยัด bandwidth
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
      });
    }
  }

  Future<void> updateData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      String? imageUrl = currentImageUrl;

      // ถ้ามีรูปใหม่ → อัปโหลดใหม่
      if (selectedImageBytes != null) {
        final fileName = '${const Uuid().v4()}.jpg';

        await supabase.storage.from('run_bk').uploadBinary(
              fileName,
              selectedImageBytes!,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        imageUrl = supabase.storage.from('run_bk').getPublicUrl(fileName);

        // ลบรูปเก่า (ถ้ามี)
        if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
          try {
            final oldFileName = currentImageUrl!.split('/').last;
            await supabase.storage.from('run_bk').remove([oldFileName]);
          } catch (_) {
            // ไม่ต้องทำอะไร ถ้าลบรูปเก่าไม่สำเร็จ
          }
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
          const SnackBar(
            content: Text('แก้ไขข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
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
        content: const Text('คุณต้องการลบข้อมูลนี้ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ลบ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
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
          const SnackBar(
            content: Text('ลบข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              if (selectedImageBytes != null || (currentImageUrl != null && currentImageUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรูปภาพ'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedImageBytes = null;
                      currentImageUrl = null; // หรือ '' ตามที่โมเดลคุณรองรับ
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        title: const Text(
          'Run Tracker (แก้ไข/ลบ)',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
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
                // -------------------- รูปภาพ --------------------
                GestureDetector(
                  onTap: isSaving ? null : _showImagePickerOptions,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: selectedImageBytes != null
                          ? Image.memory(
                              selectedImageBytes!,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            )
                          : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                              ? Image.network(
                                  currentImageUrl!,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.add_a_photo,
                                    size: imageSize * 0.45,
                                    color: Colors.grey,
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  size: imageSize * 0.45,
                                  color: Colors.grey,
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'แตะเพื่อเปลี่ยนรูป',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // -------------------- วิ่งที่ไหน --------------------
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งที่ไหน', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runWhereCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    hintText: 'เช่น สวนหลวง, สวนสาธารณะ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกสถานที่วิ่ง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // -------------------- วิ่งกับใคร --------------------
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งกับใคร', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runPersonCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    hintText: 'เช่น เพื่อน, คนเดียว...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกว่าวิ่งกับใคร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // -------------------- ระยะทาง --------------------
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ระยะทาง (กิโลเมตร)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: runDistanceCtrl,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'เช่น 5, 10, 12.5',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกระยะทาง';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'กรุณากรอกเป็นตัวเลขเท่านั้น';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // -------------------- ปุ่มบันทึก --------------------
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : updateData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 141, 49),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('บันทึกแก้ไขข้อมูล', style: TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(height: 14),

                // -------------------- ปุ่มลบ --------------------
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : deleteData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 202, 72, 11),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ลบข้อมูล', style: TextStyle(fontSize: 17)),
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