#pragma once

#include "d2ui/controls/d2_common.h"
#include "d2ui_canvas.h"
#include <stack>

class CPointScanner
{
public:
	static CPointScanner&					instance() { return g_test; }
	virtual ~CPointScanner();

	void									SetStartPoint(D2UI::CPoint pt) { m_ptStart = pt; }
	void									SetRT(D2UI::IRenderTarget* pRT) { m_pRT = pRT; }
	void									SetDE76(double range) { m_colorDE76 = range; };
	vector<D2UI::CSkPoint>					ScanPoints();


	static double							CalculateDE76(DWORD color1, DWORD color2);

private:
	CPointScanner();

	void									InitData();
	void									ReleaseData();
	vector<D2UI::CSkPoint>					DoScan();


	int										ScanHorizontalLine(int start, int end, int y, INT8 dirc);

	void									ScanVerticalLine(stack<D2UI::CSkPoint>& stk, 
		int xLeft, int xRight, int y, INT8 dirc);


	bool									IsReqPoint(int x, int y);
	bool									InBound(int x, int y);
	DWORD									GetPixel(int x, int y);
	DWORD									GetPixel(D2UI::CSkPoint pt);

private:
	static CPointScanner					g_test;

	D2UI::CSkPoint							m_ptStart; // ɨ�����
	DWORD									m_destColor; // ��Ҫ������Ŀ����ɫ
	D2UI::CAutoRefPtr<D2UI::IRenderTarget>	m_pRT; // ������ȡ��ɫֵ

	int										m_screenWidth, m_screenHeight;
	bool**									m_pixels; // ������¼ҪͿɫ�ĵ�

	double									m_colorDE76; // �������ɫֵ��ֵ��Χ
};