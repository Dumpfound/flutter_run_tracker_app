import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_run_tracker_app/models/run_model.dart';
import 'package:flutter_run_tracker_app/views/add_run_ui.dart';
import 'package:flutter_run_tracker_app/views/update_delete_run_ui.dart';

class ShowAllRunUI extends StatefulWidget {
  const ShowAllRunUI({super.key});

  @override
  State<ShowAllRunUI> createState() => _ShowAllRunUIState();
}

class _ShowAllRunUIState extends State<ShowAllRunUI> {
  final supabase = Supabase.instance.client;
  List<RunModel> runList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getAllRun();
  }

  Future<void> getAllRun() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('run_tb')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        runList = (response as List)
            .map((item) => RunModel.fromJson(item))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'ไม่สามารถโหลดข้อมูลได้\nกรุณาลองใหม่อีกครั้ง';
      });
      debugPrint('Error fetching runs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        title: const Text(
          'Run Tracker',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isLoading ? null : getAllRun,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRunUI()),
          );
          getAllRun();
        },
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (runList.isEmpty) {
      return _buildEmptyState();
    }

    return _buildListView();
  }

  // -------------------- Error State --------------------
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: getAllRun,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 5, 1, 80),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Empty State --------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.width * 0.35,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          Text(
            'วิ่งกันเถอะ',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.032,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีข้อมูลการวิ่ง',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'กดปุ่ม + ด้านล่างเพื่อเพิ่มข้อมูล',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddRunUI()),
              );
              getAllRun();
            },
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มการวิ่งครั้งแรก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 5, 1, 80),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- List View --------------------
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: getAllRun,
      color: const Color.fromARGB(255, 5, 1, 80),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: runList.length + 1, // +1 สำหรับ header
        itemBuilder: (context, index) {
          // Header (โลโก้ + ข้อความ)
          if (index == 0) {
            return Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.28,
                  height: MediaQuery.of(context).size.width * 0.28,
                ),
                const SizedBox(height: 8),
                Text(
                  'วิ่งกันเถอะ',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.028,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ทั้งหมด ${runList.length} ครั้ง',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          final run = runList[index - 1];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: index % 2 == 0
                ? const Color(0xFFE8F5E9) // เขียวอ่อน
                : const Color(0xFFE3F2FD), // ฟ้าอ่อน
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateDeleteRunUI(run: run),
                  ),
                );
                getAllRun();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // รูปภาพ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: run.runImageUrl != null && run.runImageUrl!.isNotEmpty
                          ? Image.network(
                              run.runImageUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.directions_run, size: 30, color: Colors.green),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.directions_run, size: 30, color: Colors.green),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // ข้อมูล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'วิ่งที่ไหน: ${run.runWhere}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'วิ่งกับใคร: ${run.runPerson}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${run.runDistance} กม.',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 5, 1, 80),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}