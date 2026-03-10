import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hashmicro_test/services/location_service.dart';
import 'package:hashmicro_test/features/location_master/repositories/location_repository.dart';
import 'package:hashmicro_test/features/location_master/models/location_models.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hashmicro_test/utils/ui_helpers.dart';

class LocationController extends GetxController {
  final LocationService _locationService = LocationService();
  final nameController = TextEditingController();
  final _repository = LocationRepository();

  // State untuk menyimpan koordinat terpilih
  var selectedLat = 0.0.obs;
  var selectedLng = 0.0.obs;
  var isLoading = false.obs;

  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;

  // Di dalam LocationController
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    // Langsung minta permission dan titik lokasi saat halaman dibuka
    pinCurrentLocation();
  }

  Future<void> pinCurrentLocation() async {
    try {
      isLoading.value = true;
      Position position =
          await _locationService.getCurrentLocation(); // Dari Service

      selectedLat.value = position.latitude;
      selectedLng.value = position.longitude;

      // Gerakkan kamera ke lokasi baru
      mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );

      // Ambil nama alamat dan masukkan ke UI
      await getAddressFromCoords(position.latitude, position.longitude);
    } catch (e) {
      UIHelper.showErrorDialog(title: "Error", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi simpan ke SQLite
  Future<void> saveLocation() async {
    if (nameController.text.isEmpty || selectedLat.value == 0.0) {
      UIHelper.showErrorDialog(
        title: "Error",
        message: "Nama lokasi dan koordinat tidak boleh kosong",
      );
      return;
    }

    try {
      final newLocation = LocationModel(
        name: nameController.text,
        latitude: selectedLat.value,
        longitude: selectedLng.value,
      );

      await _repository.insertLocation(newLocation);
      UIHelper.showSuccessDialog(
        title: "Sukses",
        message: "Master data lokasi berhasil disimpan!",
        onConfirm: () {
          // Tutup dialog dan halaman presensi (Get back 2 kali), kembali ke Dashboard.
          Get.close(2);
        },
      );

      // Reset form setelah simpan
      nameController.clear();
    } catch (e) {
      UIHelper.showErrorDialog(
        title: "Gagal Menyimpan",
        message: "Terjadi kesalahan saat menyimpan lokasi: ${e.toString()}",
      );
    }
  }

  var address = "".obs;

  // 1. Fungsi saat peta di-klik
  void onMapTap(LatLng latLng) async {
    selectedLat.value = latLng.latitude;
    selectedLng.value = latLng.longitude;

    // Ambil alamat dari koordinat
    await getAddressFromCoords(latLng.latitude, latLng.longitude);
  }

  // 2. Fungsi Reverse Geocoding
  Future<void> getAddressFromCoords(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks[0];
      address.value =
          "${place.street}, ${place.subLocality}, ${place.locality}";

      // Otomatis isi TextField nama dengan nama jalan / nama gedung
      nameController.text = place.name ?? "Lokasi Baru";
    } catch (e) {
      address.value = "Alamat tidak ditemukan";
    }
  }

  // Fungsi mencari koordinat dari teks alamat
  Future<void> searchAddress(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      List<Location> locations = await locationFromAddress(query);

      List<Map<String, dynamic>> resultsWithAddress = [];

      // Batasi 5 hasil pencarian untuk di reverse-geocode agar lebih cepat
      for (var loc in locations.take(5)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;

            List<String> addressParts = [];
            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }
            if (place.subLocality != null &&
                place.subLocality!.isNotEmpty &&
                place.subLocality != place.street) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }

            String fullAddr = addressParts.join(', ');
            if (fullAddr.isEmpty) {
              fullAddr =
                  "Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}";
            }

            String name = place.name ?? "";
            if (name.isEmpty || name == place.street) {
              name =
                  addressParts.isNotEmpty
                      ? addressParts.first
                      : "Lokasi Ditemukan";
            }

            resultsWithAddress.add({
              'location': loc,
              'name': name,
              'address': fullAddr,
            });
          }
        } catch (e) {
          resultsWithAddress.add({
            'location': loc,
            'name': "Lokasi Terpilih",
            'address':
                "Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}",
          });
        }
      }

      searchResults.value = resultsWithAddress; // Menampilkan hasil ke dropdown
    } catch (e) {
      log("Alamat tidak ditemukan");
    } finally {
      isSearching.value = false;
    }
  }

  // Fungsi saat hasil pencarian diklik
  void selectSearchResult(Location loc, String fullAddress, String name) {
    selectedLat.value = loc.latitude;
    selectedLng.value = loc.longitude;
    address.value = fullAddress;

    // Gunakan nama tempat spesifik
    nameController.text = name;

    // Pindahkan kamera peta
    mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
    );

    searchResults.clear(); // Tutup dropdown
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}
