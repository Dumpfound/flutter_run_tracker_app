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

  @override
  void initState() {
    super.initState();
    getAllRun();
  }

  Future<void> getAllRun() async {
    setState(() => isLoading = true);

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
      setState(() => isLoading = false);
      debugPrint('Error: $e');
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRunUI()),
          );
          getAllRun(); // กลับมาแล้วรีเฟรชข้อมูล
        },
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : runList.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Image.asset(
            'assets/images/logo.png',
            width: MediaQuery.of(context).size.width * 0.355,
            height: MediaQuery.of(context).size.width * 0.355,
            fit: BoxFit.cover,
          ),
          Text(
            'วิ่งกันเถอะ',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.0325,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: getAllRun,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: runList.length + 1,
        itemBuilder: (context, index) {
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
                const SizedBox(height: 20),
              ],
            );
          }

          final run = runList[index - 1];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateDeleteRunUI(run: run),
                ),
              );
              getAllRun();
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFE8F5E9),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: run.runImageUrl != null && run.runImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          run.runImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.directions_run, size: 40),
                        ),
                      )
                    : const Icon(Icons.directions_run, size: 40, color: Colors.green),
                title: Text(
                  'วิ่งที่ไหน: ${run.runWhere}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('วิ่งกับใคร: ${run.runPerson}   |   ${run.runDistance} กม.'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        },
      ),
    );
  }
}
