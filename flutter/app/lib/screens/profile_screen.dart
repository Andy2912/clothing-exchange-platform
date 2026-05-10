import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'my_items_screen.dart';
import 'package:app/session.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool isUploadingProfilePic = false;

  String username = "";
  String aboutMe = "";
  String profileImageUrl = "";

  bool isLoading = true;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();

  bool isEditing = false;
  bool isSaving = false;

  final String baseUrl = "http://10.0.2.2:8000";

  Future<void> fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/${AppSession.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          username = data['username'] ?? "";
          aboutMe = data['about_me'] ?? "";
          profileImageUrl = data['profile_picture'] ?? "";

          usernameController.text = username;
          aboutMeController.text = aboutMe;

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trades/${AppSession.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.where((trade) => trade['status'] == 'completed').toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<void> saveProfile() async {
    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/${AppSession.userId}/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'about_me': aboutMeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          username = data['username'] ?? usernameController.text;
          aboutMe = data['about_me'] ?? aboutMeController.text;
          isEditing = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile updated")));
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
    }

    setState(() {
      isSaving = false;
    });
  }

  Future<void> changeProfilePicture() async {
    if (AppSession.userId == null) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      isUploadingProfilePic = true;
    });

    try {
      var uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-pic'),
      );

      uploadRequest.files.add(
        await http.MultipartFile.fromPath('file', pickedFile.path),
      );

      final uploadResponse = await uploadRequest.send();
      final uploadResponseBody = await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload image');
      }

      final uploadData = jsonDecode(uploadResponseBody);
      final String uploadedImageUrl = uploadData['url'];

      final saveResponse = await http.put(
        Uri.parse('$baseUrl/profile/${AppSession.userId}/profile-pic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'profile_picture': uploadedImageUrl}),
      );

      if (saveResponse.statusCode == 200) {
        final data = jsonDecode(saveResponse.body);

        setState(() {
          profileImageUrl = data['profile_picture'] ?? uploadedImageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      } else {
        print(saveResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile picture')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isUploadingProfilePic = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  Widget _buildMenuItem({
    required String text,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(18) : Radius.zero,
          topRight: isFirst ? const Radius.circular(18) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurpleDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: const Color(0xFFB326D1).withOpacity(0.18),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe0e0e0),
      appBar: AppBar(
        title: const Text("My profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFFFFFFFF), // pure white
              Color.fromARGB(255, 241, 229, 255), // VERY light purple
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Edit button (top right inside body)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () {
                                    if (isEditing) {
                                      saveProfile();
                                    } else {
                                      setState(() {
                                        isEditing = true;
                                      });
                                    }
                                  },
                            icon: Icon(
                              isEditing ? Icons.save : Icons.edit,
                              size: 18,
                            ),
                            label: Text(isEditing ? "Save" : "Edit"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    //stack voor widgets op elkaar te plaatsen
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 75,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage("$baseUrl$profileImageUrl")
                              : const AssetImage(
                                      "assets/ProfilePicturePlaceholder.png",
                                    )
                                    as ImageProvider,
                        ),
                        GestureDetector(
                          onTap: isUploadingProfilePic
                              ? null
                              : changeProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB326D1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: isUploadingProfilePic
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: 325,
                      child: isEditing
                          ? TextField(
                              controller: usernameController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0x7fffffff),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                hintText: "Username",
                              ),
                            )
                          : Text(
                              username,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 32),
                            ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(8),
                      width: 325,
                      height: 125,
                      decoration: BoxDecoration(
                        color: const Color(0x7fffffff),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              191,
                              0,
                              255,
                            ).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isEditing
                          ? TextField(
                              controller: aboutMeController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write something about yourself",
                              ),
                            )
                          : Text(
                              aboutMe.isNotEmpty ? aboutMe : "No bio yet",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                    ),

                    const SizedBox(height: 15),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: 325,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFFB326D1), // purple border
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewListing(),
                            ),
                          );
                        },
                        child: Align(
                          alignment: Alignment(-0.75, 0),
                          child: Text(
                            "New listing",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: 325,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFB326D1),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            text: "Account",
                            isFirst: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountPage(),
                                ),
                              );
                            },
                          ),
                          _buildPurpleDivider(),
                          _buildMenuItem(
                            text: "My items",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyItemsPage(),
                                ),
                              );
                            },
                          ),

                          _buildPurpleDivider(),
                          _buildMenuItem(
                            text: "History",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryPage(),
                                ),
                              );
                            },
                          ),
                          _buildPurpleDivider(),
                          _buildMenuItem(
                            text: "Settings",
                            isLast: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15),

                    Align(
                      alignment: Alignment(-0.65, 0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffd00000),
                        ),
                        child: Text(
                          "Sign out",
                          style: TextStyle(color: Color(0xffffffff)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: const Center(child: Text("Account Page")),
    );
  }
}

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Matches")),
      body: const Center(child: Text("Matches Page")),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String baseUrl = "http://10.0.2.2:8000";
  List<dynamic> trades = [];
  bool isLoading = true;

  Future<void> loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trades/${AppSession.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        setState(() {
          trades = data
              .where((trade) => trade['status'] == 'completed')
              .toList();
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      trades = [];
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trades.isEmpty
          ? const Center(
              child: Text(
                "No completed exchanges yet.",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades[index];
                final isUser1 = trade['user1_id'] == AppSession.userId;
                final myItemName = isUser1
                    ? trade['cloth1_name']
                    : trade['cloth2_name'];
                final otherItemName = isUser1
                    ? trade['cloth2_name']
                    : trade['cloth1_name'];
                final otherUsername = isUser1
                    ? trade['user2_username']
                    : trade['user1_username'];
                final completedDate =
                    trade['created_at']?.toString().split(' ')[0] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFB326D1),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Exchanged with $otherUsername",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("You gave: $myItemName"),
                      const SizedBox(height: 6),
                      Text("You received: $otherItemName"),
                      const SizedBox(height: 12),
                      Text(
                        "Completed on: $completedDate",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color.fromARGB(255, 196, 129, 255)],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text("Settings"),
              centerTitle: true,
              backgroundColor: Color(0x00000000),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 325,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("Settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            SizedBox(
              width: 325,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
                onPressed: () {},
                child: Align(
                  alignment: Alignment(-0.75, 0),
                  child: Text("More settings", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewListing extends StatefulWidget {
  const NewListing({super.key});

  @override
  State<NewListing> createState() => _NewListingState();
}

class _NewListingState extends State<NewListing> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController brandController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  String selectedCategory = "shirts";
  String selectedCondition = "good";

  File? _image;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> createListing() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        brandController.text.isEmpty ||
        sizeController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/listings/'),
      );

      request.fields['name'] = nameController.text;
      request.fields['description'] = descriptionController.text;
      request.fields['category'] = selectedCategory;
      request.fields['brand'] = brandController.text;
      request.fields['size'] = sizeController.text;
      request.fields['condition_rating'] = selectedCondition;
      request.fields['user_id'] = AppSession.userId.toString();

      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context); // go back after success
      } else {
        throw Exception('Failed to create listing');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error creating listing")));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color.fromARGB(255, 196, 129, 255)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppBar(
                title: const Text("New listing"),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: 325,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                    hintText: "Item name",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 325,
                  height: 325,
                  decoration: BoxDecoration(
                    color: const Color(0x7f000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _image == null
                      ? const Icon(
                          Icons.add_a_photo,
                          color: Colors.white,
                          size: 40,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 325,
                child: TextField(
                  controller: descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                    hintText: "Item description",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 325,
                child: TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                    hintText: "Brand",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 325,
                child: TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                    hintText: "Size",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 325,
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "shirts", child: Text("Shirts")),
                    DropdownMenuItem(value: "jackets", child: Text("Jackets")),
                    DropdownMenuItem(value: "hoodies", child: Text("Hoodies")),
                    DropdownMenuItem(value: "pants", child: Text("Pants")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 325,
                child: DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0x7fffffff),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "like_new",
                      child: Text("Like new"),
                    ),
                    DropdownMenuItem(value: "good", child: Text("Good")),
                    DropdownMenuItem(value: "worn", child: Text("Worn")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCondition = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 325,
                height: 70,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createListing,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Post", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
