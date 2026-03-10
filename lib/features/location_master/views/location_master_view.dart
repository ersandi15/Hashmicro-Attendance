import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/location_controller.dart';

// lib/dashboard/views/location_master_view.dart

class LocationMasterView extends GetView<LocationController> {
  const LocationMasterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Membuat Map memenuhi layar
      // appBar: AppBar(
      //   title: const Text(
      //     "Set Office Location",
      //     style: TextStyle(color: Colors.black87),
      //   ),
      //   backgroundColor: Colors.white.withValues(alpha: 0.8),
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.black87),
      // ),
      body: Stack(
        children: [
          // Background Map
          Obx(
            () => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-7.9839, 112.6214),
                zoom: 16,
              ),
              onMapCreated:
                  (mapController) => controller.mapController = mapController,
              onTap: (latLng) => controller.onMapTap(latLng),
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Kita buat tombol custom
              zoomControlsEnabled: false,
              markers: {
                if (controller.selectedLat.value != 0.0)
                  Marker(
                    markerId: const MarkerId("selected_point"),
                    position: LatLng(
                      controller.selectedLat.value,
                      controller.selectedLng.value,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
              },
            ),
          ),

          // 2. Custom Back Button (Pengganti AppBar)
          Positioned(
            top: 60,
            left: 15,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // 2. Lapisan Atas: Search Bar & Dropdown
          Positioned(
            top: 50,
            left: 70, // Beri jarak untuk tombol back
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: TextField(
                    controller: controller.nameController,
                    onChanged:
                        (val) =>
                            controller.searchAddress(val), // Trigger pencarian
                    decoration: const InputDecoration(
                      hintText: "Cari alamat kantor...",
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),

                // Dropdown hasil pencarian yang melayang
                Obx(
                  () =>
                      controller.searchResults.isNotEmpty
                          ? Container(
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: controller.searchResults.length,
                              itemBuilder: (context, index) {
                                final item = controller.searchResults[index];
                                final loc =
                                    item['location'] as dynamic; // Location
                                final name = item['name'] as String;
                                final address = item['address'] as String;

                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Colors.blueAccent,
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap:
                                      () => controller.selectSearchResult(
                                        loc,
                                        address,
                                        name,
                                      ),
                                );
                              },
                            ),
                          )
                          : const SizedBox(),
                ),
              ],
            ),
          ),

          // Panel Input yang Melayang (Floating)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Ambil Lokasi Saat Ini
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () => controller.pinCurrentLocation(),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),

                // Card Detail & Save
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.business_rounded),
                          hintText: "Nama Kantor/Lokasi",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(
                        () => Text(
                          controller.address.value.isEmpty
                              ? "Ketuk peta untuk memilih lokasi"
                              : controller.address.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => controller.saveLocation(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Simpan Master Data",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
