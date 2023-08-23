#include "stdafx.h"
#include "test.h"
#include "common/log.h"

#define		COLOR_TRANSPARENT		0x00000000 // ͸��ɫ

CPointScanner CPointScanner::g_test;

CPointScanner::CPointScanner()
	: m_ptStart(-1, -1)
	, m_screenWidth(GetSystemMetrics(SM_CXSCREEN))
	, m_screenHeight(GetSystemMetrics(SM_CYSCREEN))
	, m_colorDE76(0)
	, m_destColor(COLOR_TRANSPARENT)
{

}

CPointScanner::~CPointScanner()
{
	ReleaseData();
}

vector<D2UI::CSkPoint> CPointScanner::ScanPoints()
{
	vector<D2UI::CSkPoint> list;
	if (m_ptStart.x < 0 || m_ptStart.y < 0 || !m_pRT) return list;

	InitData();
	list = DoScan();
	ReleaseData();

	return list;
}

/**
 * ��ʼ������
 */
void CPointScanner::InitData()
{
	if (m_screenWidth <= 0 || m_screenHeight <= 0)
		return;

	m_pixels = new bool* [m_screenWidth];
	for (int i = 0; i < m_screenWidth; i++)
	{
		m_pixels[i] = new bool[m_screenHeight];
		ZeroMemory(m_pixels[i], m_screenHeight * sizeof(bool));
	}
}

/**
 * �ͷ�����
 */
void CPointScanner::ReleaseData()
{
	if (m_pixels == NULL)
		return;

	for (int i = 0; i < m_screenHeight; i++)
		delete[] m_pixels[i];
	delete[] m_pixels;

	m_pixels = NULL;
}

DWORD CPointScanner::GetPixel(int x, int y)
{
	if (m_pRT)
		return m_pRT->GetPixel(x, y);
	return COLOR_TRANSPARENT;
}

DWORD CPointScanner::GetPixel(D2UI::CSkPoint pt)
{
	return GetPixel(pt.x, pt.y);
}

vector<D2UI::CSkPoint> CPointScanner::DoScan()
{
	vector <D2UI::CSkPoint> lst;
	if (m_pixels == NULL) return lst;

	// �õ�����Ҫ��Ŀ����ɫ
	m_destColor = GetPixel(m_ptStart);
	if (m_destColor == COLOR_TRANSPARENT) return lst;

	// ��ʼ��ջ
	std::stack<D2UI::CSkPoint> stk;
	stk.push(m_ptStart);
	// ɨ����Ϊy
	while (!stk.empty())
	{
		auto& front = stk.top();
		stk.pop();
		int now_x = front.x, now_y = front.y; // ��ǰɨ��ĵ� x��y����
		m_pixels[now_x][now_y] = TRUE; // ��ǵ�ǰ���Ѿ�ɨ���

		// ����ɨ��������ɨ
		int xLeft = ScanHorizontalLine(now_x, 0, now_y, -1); // ��߽�
		// ����ɨ��������ɨ
		int xRight = ScanHorizontalLine(now_x, m_screenWidth - 1, now_y, 1); // �ұ߽�

		// ɨ������������
		ScanVerticalLine(stk, xLeft, xRight, now_y + (-1), -1);
		ScanVerticalLine(stk, xLeft, xRight, now_y + (1), 1);
	}

	for (int i = 0; i < m_screenWidth; i++)
		for (int j = 0; j < m_screenHeight; j++)
			if (m_pixels[i][j]) lst.push_back(D2UI::CSkPoint(i, j));

	return lst;
}

/**
 * @remark:		ɨ��� ��� �յ� Ϊ������ [start, end]
 * @plist:		��������
 * @start:		ɨ�迪ʼ�����
 * @end:		ɨ�迪ʼ���յ�
 * @line:		ɨ���ߵ�y����
 * @dirc:		ɨ��ķ���-1��ʾ����ߣ�1��ʾ���ҡ�
 */
int CPointScanner::ScanHorizontalLine(int start, int end, int y, INT8 dirc)
{
	// �ж��Ƿ񵽴��յ�
#define NotReachEnd(direction, now_postion, end) \
    (direction) < (0) ? (now_postion) >= (end) : (now_postion) <= (end)

	// �߽�ļ�����������յ㣬��Ϊ���������Խ����
	int endPoint = end;

	for (int i = start + dirc; NotReachEnd(dirc, i, end); i += dirc)
	{
		if (IsReqPoint(i, y))
		{
			m_pixels[i][y] = TRUE;
		}
		else
		{
			// ��ȥdirc�����෴�ķ�����һ���㣬��ΪѰ�ҵ������յ���ͼ���ڲ��ڲ��ĵ㣬�����Ǳ߽��
			endPoint = i - dirc;
			break;
		}
	}

	return endPoint;
}

/**
 * @remark:		����dirc��������ɨ�裬Ѱ���µ�ɨ���ѹ��stk������[xLeft, xRight]
 * @plist:		��������
 * @xLeft:		ɨ�迪ʼ�����
 * @xRight:		ɨ�迪ʼ���յ�
 * @y:			ɨ���ߵ�y����
 * @dirc:		ɨ��ķ���-1��ʾ���ϣ�1��ʾ���¡�
 */
void CPointScanner::ScanVerticalLine(stack<D2UI::CSkPoint>& stk, int xLeft, int xRight, int y, INT8 dirc)
{
	// ����һ���������� ����
	for (int i = xLeft; i <= xRight; i++)
	{
		if (IsReqPoint(i, y))
		{
			int rBound = i + 1; // rigth boundary
			// �ҵ����ұߵı߽� ��ջ
			while (IsReqPoint(rBound, y))
				rBound++;

			i = --rBound;
			stk.push(D2UI::CSkPoint(rBound, y));
		}
	}
}

/**
 * @remark: �Ƿ�������Ҫ�ĵ� Is it a required point
 * @return: ����˵�����Ҫ�ռ����򷵻�true
 */
bool CPointScanner::IsReqPoint(int x, int y)
{
	if (!InBound(x, y)) return FALSE;
	DWORD nowPosColor = GetPixel(x, y);
	double de76 = CalculateDE76(nowPosColor, m_destColor);
	return de76 <= m_colorDE76 && !m_pixels[x][y];
}

/**
 * @remark: �ж��Ƿ��ڱ߽���
 */
bool CPointScanner::InBound(int x, int y)
{
	return (x >= 0 && x < m_screenWidth && y >= 0 && y < m_screenHeight);
}

/**
 * @remark: ʹ��DE76��ʽ������ɫ��ֵ
 * @color1: BGR��ʽ
 * @color2: BGR��ʽ
 */
double CPointScanner::CalculateDE76(DWORD color1, DWORD color2)
{
	BYTE r1 = GetRValue(color1);
	BYTE g1 = GetGValue(color1);
	BYTE b1 = GetBValue(color1);

	BYTE r2 = GetRValue(color2);
	BYTE g2 = GetGValue(color2);
	BYTE b2 = GetBValue(color2);

	double deltaL = 0.299 * (r2 - r1) + 0.587 * (g2 - g1) + 0.114 * (b2 - b1);
	double deltaA = r2 - r1 - deltaL;
	double deltaB = b2 - b1 - deltaL;

	return sqrt(deltaA * deltaA + deltaB * deltaB + deltaL * deltaL);
}