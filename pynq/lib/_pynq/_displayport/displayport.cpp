// #define _GNU_SOURCE

#include <cstdint>
#include <ctime>
#include <iostream>
#include <map>
#include <memory>
#include <vector>
#include <stdexcept>

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm/drm_fourcc.h>
#include <sys/mman.h>

#include <boost/scope_exit.hpp>

extern "C" {
struct video_mode {
	int width;
	int height;
	int refresh;
};

void* pynqvideo_device_init(int fd);
int pynqvideo_device_set_mode(void* device, int width, int height,
		int refresh, int colorspace);
void pynqvideo_device_close(void* device);
void pynqvideo_device_handle_events(void* device);

void* pynqvideo_frame_new(void* device);
int pynqvideo_frame_write(void* device, void* frame);
uint64_t pynqvideo_frame_physaddr(void* frame);
void* pynqvideo_frame_data(void* frame);
uint64_t pynqvideo_frame_size(void* frame);
uint32_t pynqvideo_frame_stride(void* frame);
void pynqvideo_frame_free(void* device, void* frame);
int pynqvideo_num_modes(void* device);
int pynqvideo_get_modes(void* device, struct video_mode* modes, int length);

}

namespace pynqvideo {

class os_error : std::runtime_error {
public: os_error(const std::string& what, int error):
	std::runtime_error(what),
	error(error) {}

	int error;
};

size_t fourcc2bpp(uint32_t fourcc)
{
	size_t bpp;

	/* look up bits per pixel */
	switch (fourcc) {
	case DRM_FORMAT_RGB332:
	case DRM_FORMAT_BGR233:
		bpp = 8;
		break;
	case DRM_FORMAT_XBGR4444:
	case DRM_FORMAT_RGBX4444:
	case DRM_FORMAT_BGRX4444:
	case DRM_FORMAT_ABGR4444:
	case DRM_FORMAT_RGBA4444:
	case DRM_FORMAT_BGRA4444:
	case DRM_FORMAT_XBGR1555:
	case DRM_FORMAT_RGBX5551:
	case DRM_FORMAT_BGRX5551:
	case DRM_FORMAT_ABGR1555:
	case DRM_FORMAT_RGBA5551:
	case DRM_FORMAT_BGRA5551:
	case DRM_FORMAT_RGB565:
	case DRM_FORMAT_BGR565:
		bpp = 16;
		break;
	case DRM_FORMAT_RGB888:
	case DRM_FORMAT_BGR888:
		bpp = 24;
		break;
	case DRM_FORMAT_XBGR8888:
	case DRM_FORMAT_RGBX8888:
	case DRM_FORMAT_ABGR8888:
	case DRM_FORMAT_RGBA8888:
	case DRM_FORMAT_XRGB2101010:
	case DRM_FORMAT_XBGR2101010:
	case DRM_FORMAT_RGBX1010102:
	case DRM_FORMAT_BGRX1010102:
	case DRM_FORMAT_ARGB2101010:
	case DRM_FORMAT_ABGR2101010:
	case DRM_FORMAT_RGBA1010102:
	case DRM_FORMAT_BGRA1010102:
		bpp = 32;
		break;
	default:
		return 0;
	}

	/* return bytes required to hold one pixel */
	return (bpp + 7) >> 3;
}

class frame {
public:
	frame(int fd, int width, int height, uint32_t fourcc) {
		m_fd = fd;
		drm_mode_create_dumb creq;
		memset(&creq, 0, sizeof(creq));
		creq.width = width;
		creq.height = height;
		creq.bpp = fourcc2bpp(fourcc) * 8;
		int ret = drmIoctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq);

		if (ret < 0) {
			throw os_error("Cannot create dumb buffer", -ret);
		}

		bo_handle = creq.handle;
		stride = creq.pitch;
		size = creq.size;
		bool commit = false;
		BOOST_SCOPE_EXIT(&commit, &bo_handle, &fd) {
			if (!commit) {
				drm_mode_destroy_dumb dreq;
				memset(&dreq, 0, sizeof(dreq));
				dreq.handle = bo_handle;
				drmIoctl(fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq);
			}
		} BOOST_SCOPE_EXIT_END

		drm_prime_handle prime;
		memset(&prime, 0, sizeof(prime));
		prime.handle = bo_handle;

		ret = drmIoctl(fd, DRM_IOCTL_PRIME_HANDLE_TO_FD, &prime);
		if (ret) {
			std::cerr << "Failed to create buffer FD: " << ret << std::endl;
			throw os_error("Failed to create buffer FD", ret);
		}
		m_buf_fd = prime.fd;

		BOOST_SCOPE_EXIT(&commit, &m_buf_fd) {
			if (!commit) close(m_buf_fd);
		} BOOST_SCOPE_EXIT_END

		uint32_t offsets[4] = { 0 };
		uint32_t pitches[4] = {creq.pitch};
		uint32_t bo_handles[4] = {(uint32_t)bo_handle};

		ret = drmModeAddFB2(fd, width, height, fourcc, bo_handles, pitches, offsets, &fb_handle, 0);
		if (ret) {
			std::cerr << "Error: " << ret << std::endl;
			throw os_error("Could not add frame buffer", ret);
		}

		BOOST_SCOPE_EXIT(&commit, &fd, &fb_handle) {
			if (!commit) {
				drmModeRmFB(fd, fb_handle);
			}
		} BOOST_SCOPE_EXIT_END

		drm_mode_map_dumb mreq;
		memset(&mreq, 0, sizeof(mreq));
		mreq.handle = bo_handle;
		ret = drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq);
		if (ret) {
			throw os_error("Cannot map dumb buffer", ret);
		}
		data = mmap(0, creq.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, mreq.offset);
		std::cerr << "Offset: " << mreq.offset << std::endl;
		if (data == MAP_FAILED) {
			throw std::runtime_error("Cannot mmap dumb buffer");
		}
		memset(data, 0, size);

		physical_address = mreq.offset;

		std::cout << "Created Frame Buffer: " << physical_address << std::endl;
		
		commit = true;
	}

	int bo_handle;
	uint32_t fb_handle;
	void* data;
	unsigned long physical_address;
	uint32_t size;
	uint32_t stride;
private:

	int m_buf_fd;
	int m_fd;
};

class device {
public:
	device(int fd):
		m_fd(fd),
		m_pending(false),
		m_saved_crtc(NULL),
		m_active_frame(NULL)
	{
		memset(&m_ev, 0, sizeof(m_ev));
		m_ev.version = 2;
		m_ev.page_flip_handler = page_flip_handler;
		uint64_t has_dumb;
		if (drmGetCap(m_fd, DRM_CAP_DUMB_BUFFER, &has_dumb) < 0 || !has_dumb) {
			throw std::runtime_error("Device does not support DUMB buffers");
		}
		enumerate_modes();
	}

	~device() {
		if (m_saved_crtc) {
			drmModeSetCrtc(m_fd,
				m_saved_crtc->crtc_id,
				m_saved_crtc->buffer_id,
				m_saved_crtc->x,
				m_saved_crtc->y,
				&m_conn,
				1,
				&m_saved_crtc->mode);
			drmModeFreeCrtc(m_saved_crtc);
		}
	}

	int set_mode(int width, int height, int refresh, int fourcc) {
		find_conn(width, height, refresh);
		m_fourcc = fourcc;
		auto frame = new_frame();
		m_saved_crtc = drmModeGetCrtc(m_fd, m_crtc);
		int ret = drmModeSetCrtc(m_fd, m_crtc, frame->fb_handle, 0, 0, &m_conn, 1, &m_info);
		if (ret) {
			throw std::runtime_error("Could not set CRTC");
		}
		m_active_frame = frame;
		return 0;
	}

	frame* new_frame() {
		if (!m_free_frames.empty()) {
			auto newframe = m_free_frames.back();
			m_free_frames.pop_back();
			return newframe;
		} else {
			auto newframe = std::make_shared<frame>(m_fd, m_info.hdisplay, m_info.vdisplay, m_fourcc);
			m_frame_map.insert(std::make_pair(newframe->data, newframe));		
			return newframe.get();
		}
	}

	void free_frame(frame* f) {
		if (std::find(m_free_frames.begin(), m_free_frames.end(), f) != m_free_frames.end()) {
			throw std::logic_error("Trying to free already free'd frame");
		}
		if (m_free_frames.size() > 5) {
			m_frame_map.erase(f->data);
		} else {
			m_free_frames.push_back(f);
		}
	}

	bool write_frame(frame* f) {
		//int ret = drmModePageFlip(m_fd, m_crtc, f->fb_handle, DRM_MODE_PAGE_FLIP_EVENT, this);
		int ret = drmModePageFlip(m_fd, m_crtc, f->fb_handle, DRM_MODE_PAGE_FLIP_EVENT, this);
		m_pending = true;
		if (ret == -EBUSY) {
			return false;
		} else if (ret) {
			std::cerr << "Failed to write frame: " << ret << std::endl;
			throw std::runtime_error("Failed to write frame");
		}
		if (m_active_frame) {
			free_frame(m_active_frame);
		}
		m_active_frame = f;
		return true;
	}

	void handle_events() {
		drmHandleEvent(m_fd, &m_ev);
	}	

	const std::vector<video_mode>& modes() {
		return m_modes;
	}

private:	
	static void page_flip_handler(int fd, unsigned int frame, unsigned int sec, unsigned int usec, void* data) {
		device* dev = static_cast<device*>(data);
		dev->m_pending = false;
	}

	void enumerate_modes() {
		drmModeRes* res;
		drmModeConnector *conn;

		res = drmModeGetResources(m_fd);
		if (!res) {
			throw std::runtime_error("Cannot retrieve DRM resources");
		}
		BOOST_SCOPE_EXIT(&res) {
			drmModeFreeResources(res);
		} BOOST_SCOPE_EXIT_END

		m_info.hdisplay = 0;

		for (int i = 0; i < res->count_connectors; ++i) {
			conn = drmModeGetConnector(m_fd, res->connectors[i]);
			if (!conn) {
				std::cerr << "Cannot retrieve DRM connector :" << errno << std::endl;
			}
			BOOST_SCOPE_EXIT(&conn) {
				drmModeFreeConnector(conn);
			} BOOST_SCOPE_EXIT_END

			if (conn->connection != DRM_MODE_CONNECTED) {
				std::cerr << "Ignoring unconnected port" << std::endl;
				continue;
			}

			if (conn->count_modes == 0) {
				std::cerr << "Ingnoring connector with no modes" << std::endl;
				continue;
			}

			for (int j = 0; j < conn->count_modes; ++j) {
				const auto& mode = conn->modes[j];
				m_modes.push_back(video_mode{mode.hdisplay, mode.vdisplay, mode.vrefresh});
			}
		}
	}

	void find_conn(int width, int height, int refresh) {
		drmModeRes* res;
		drmModeConnector *conn;

		res = drmModeGetResources(m_fd);
		if (!res) {
			throw std::runtime_error("Cannot retrieve DRM resources");
		}
		BOOST_SCOPE_EXIT(&res) {
			drmModeFreeResources(res);
		} BOOST_SCOPE_EXIT_END

		m_info.hdisplay = 0;

		for (int i = 0; i < res->count_connectors; ++i) {
			conn = drmModeGetConnector(m_fd, res->connectors[i]);
			if (!conn) {
				std::cerr << "Cannot retrieve DRM connector :" << errno << std::endl;
			}
			BOOST_SCOPE_EXIT(&conn) {
				drmModeFreeConnector(conn);
			} BOOST_SCOPE_EXIT_END

			if (conn->connection != DRM_MODE_CONNECTED) {
				std::cerr << "Ignoring unconnected port" << std::endl;
				continue;
			}

			if (conn->count_modes == 0) {
				std::cerr << "Ingnoring connector with no modes" << std::endl;
				continue;
			}

			for (int j = 0; j < conn->count_modes; ++j) {
				const auto& mode = conn->modes[j];
				if (mode.hdisplay == width && mode.vdisplay == height && mode.vrefresh == refresh) {
					m_info = mode;
					m_conn = conn->connector_id;
					break;
				}
			}
			find_crtc(res, conn);
		}

		if (!m_info.hdisplay) {
			throw std::runtime_error("Could not find compatible mode");
		}

	}

	void find_crtc(drmModeRes* res, drmModeConnector* conn) {
		m_crtc = 0;
		if (conn->encoder_id) {
			drmModeEncoder* enc = NULL;
			enc = drmModeGetEncoder(m_fd, conn->encoder_id);
			if (enc) {
				if (enc->crtc_id) {
					m_crtc = enc->crtc_id;
				}
				drmModeFreeEncoder(enc);
			}
		}
		if (!m_crtc) {
			for (int i = 0; i < conn->count_encoders; ++i) {
				drmModeEncoder* enc = drmModeGetEncoder(m_fd, conn->encoders[i]);
				if (!enc) {
					continue;
				}
				BOOST_SCOPE_EXIT(&enc) {
					drmModeFreeEncoder(enc);
				} BOOST_SCOPE_EXIT_END
				for (int j = 0; j < res->count_crtcs; ++j) {
					if (enc->possible_crtcs & (1 << j)) {
						m_crtc = res->crtcs[j];
						break;
					}
				}
			}
		}
		if (!m_crtc) {
			throw std::runtime_error("Could not find CRTC");
		}
	}

	int m_fd;
	uint32_t m_conn;
	uint32_t m_crtc;
	uint32_t m_fourcc;
	bool m_pending;
	drmModeModeInfo m_info;
	drmModeCrtc* m_saved_crtc;
	drmEventContext m_ev;
	std::map<void*, std::shared_ptr<frame> > m_frame_map;
	std::vector<frame*> m_free_frames;
	frame* m_active_frame;
	std::vector<video_mode> m_modes;
};

}

void* pynqvideo_device_init(int fd) {
	auto dev = new pynqvideo::device(fd);
	return static_cast<void*>(dev);
}

int pynqvideo_device_set_mode(void* device, int width, int height,
		int refresh, int colorspace) {
	auto dev = static_cast<pynqvideo::device*>(device);
	try {
		dev->set_mode(width, height, refresh, colorspace);
	}
	catch(pynqvideo::os_error& e) {
		return e.error;
	}
	return 0;
}

void pynqvideo_device_close(void* device) {
	auto dev = static_cast<pynqvideo::device*>(device);
	delete dev;
}

void pynqvideo_device_handle_events(void* device) {
	auto dev = static_cast<pynqvideo::device*>(device);
	dev->handle_events();
}

void* pynqvideo_frame_new(void* device) {
	auto dev = static_cast<pynqvideo::device*>(device);
	auto frame = dev->new_frame();
	return static_cast<void*>(frame);
}

int pynqvideo_frame_write(void* device, void* frame) {
	auto dev = static_cast<pynqvideo::device*>(device);
	auto f = static_cast<pynqvideo::frame*>(frame);
	bool ret = 0;
	try {
		ret = dev->write_frame(f);
	}
	catch (pynqvideo::os_error& e) {
		return e.error;
	}
	return ret? 0: -1;
}

uint64_t pynqvideo_frame_physaddr(void* frame) {
	auto f = static_cast<pynqvideo::frame*>(frame);
	return f->physical_address;
}

void* pynqvideo_frame_data(void* frame) {
	auto f = static_cast<pynqvideo::frame*>(frame);
	return f->data;
}

uint64_t pynqvideo_frame_size(void* frame) {
	auto f = static_cast<pynqvideo::frame*>(frame);
	return f->size;
}

uint32_t pynqvideo_frame_stride(void* frame) {
	auto f = static_cast<pynqvideo::frame*>(frame);
	return f->stride;
}

void pynqvideo_frame_free(void* device, void* frame) {
	auto dev = static_cast<pynqvideo::device*>(device);
	auto f = static_cast<pynqvideo::frame*>(frame);
	dev->free_frame(f);
}

int pynqvideo_num_modes(void* device) {
	return static_cast<pynqvideo::device*>(device)->modes().size();
}

int pynqvideo_get_modes(void* device, video_mode* modes, int length) {
	const std::vector<video_mode>& source_modes = static_cast<pynqvideo::device*>(device)->modes();
	int to_copy = std::min(length, (int)source_modes.size());
	std::copy(source_modes.begin(), source_modes.begin() + to_copy, modes);
	return source_modes.size();
}
